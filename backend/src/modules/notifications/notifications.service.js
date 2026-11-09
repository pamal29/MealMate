async function createNotification(executor, { userId, orderId = null, type, title, body }) {
  const { rows } = await executor.query(
    `insert into notifications (user_id, order_id, type, title, body)
     values ($1, $2, $3, $4, $5)
     returning id, user_id, order_id, type, title, body, is_read, created_at`,
    [userId, orderId, type, title, body]
  );
  return rows[0];
}

async function notifyOrderStatus(executor, order) {
  if (order.status === 'accepted') {
    return createNotification(executor, {
      userId: order.student_id,
      orderId: order.id,
      type: 'order_accepted',
      title: 'Order accepted',
      body: `Your order has been accepted and will be ready in about ${order.estimated_minutes} minutes.`,
    });
  }

  return createNotification(executor, {
    userId: order.student_id,
    orderId: order.id,
    type: 'order_rejected',
    title: 'Order rejected',
    body: 'Sorry, the shop could not accept your order.',
  });
}

module.exports = { createNotification, notifyOrderStatus };