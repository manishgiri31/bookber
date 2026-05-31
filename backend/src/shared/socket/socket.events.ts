export type NotificationSocketEvents = {
  "notification.sent": {
    userId: string;
    type: string;
    title: string;
    body: string;
  };
};
