async function createNotification(executor, {userId, orderId = null, type, title, body}){
  const {rows} = await executor.query(
    `insert into notifications (user_id, order_id, type, title, body)
     values ($1, $2, $3, $4, $5)
     returning id, user_id, order_id, type, title, body, is_read, created_at`,
    [userId, orderId, type, title, body]
  );
  return rows[0];
}

module.exports = { createNotification };