import consumer from "./consumer"

const createChatChannel = (roomId, onReceive) => {
  return consumer.subscriptions.create(
    { channel: "ChatChannel", room: roomId },
    {
      received(data) {
        onReceive(data)
      },
      sendMessage(message) {
        this.perform("receive", message)
      }
    }
  )
}

export default createChatChannel
