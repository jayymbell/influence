class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: %i[show update destroy send_message]

  # GET /conversations
  def index
    @conversations = policy_scope(Conversation).order(updated_at: :desc)
    authorize Conversation

    serialized = @conversations.map do |c|
      ConversationSerializer.new(c).serializable_hash[:data][:attributes]
    end
    render_success(data: { conversations: serialized }, message: "Conversations found.")
  end

  # GET /conversations/:id
  def show
    authorize @conversation

    conversation_data = ConversationSerializer.new(@conversation).serializable_hash[:data][:attributes]
    render_success(data: { conversation: conversation_data }, message: "Conversation found.")
  end

  # POST /conversations
  def create
    @conversation = current_user.conversations.new(conversation_params)
    authorize @conversation

    if @conversation.save
      conversation_data = ConversationSerializer.new(@conversation).serializable_hash[:data][:attributes]
      render_success(data: { conversation: conversation_data }, message: "Conversation created.", status: :created)
    else
      render_error(errors: @conversation.errors.full_messages, message: "Conversation creation failed.")
    end
  end

  # PATCH/PUT /conversations/:id
  def update
    authorize @conversation

    if @conversation.update(conversation_params)
      conversation_data = ConversationSerializer.new(@conversation).serializable_hash[:data][:attributes]
      render_success(data: { conversation: conversation_data }, message: "Conversation updated.")
    else
      render_error(errors: @conversation.errors.full_messages, message: "Conversation update failed.")
    end
  end

  # DELETE /conversations/:id
  def destroy
    authorize @conversation
    @conversation.destroy!
    render_success(message: "Conversation deleted.")
  end

  # POST /conversations/:id/messages
  #
  # Saves the user's message, forwards it to the AI service, saves the
  # assistant reply, and returns the updated conversation.
  def send_message
    authorize @conversation

    content = params.dig(:message, :content)
    if content.blank?
      return render_error(errors: ["Message content can't be blank"], message: "Message creation failed.")
    end

    # Persist the user message
    user_message = @conversation.messages.create!(role: "user", content: content)

    # Auto-title from first message
    @conversation.generate_title_from_first_message!

    # Call the AI service
    begin
      ai_response = AiClient.prompt(content)
    rescue AiClient::AiServiceError => e
      return render_error(
        errors: [e.message],
        message: "AI service error.",
        status: :bad_gateway
      )
    end

    # Persist the assistant reply
    @conversation.messages.create!(role: "assistant", content: ai_response)
    @conversation.touch # bump updated_at so it sorts to the top

    conversation_data = ConversationSerializer.new(@conversation.reload).serializable_hash[:data][:attributes]
    render_success(data: { conversation: conversation_data }, message: "Message sent.")
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def conversation_params
    params.expect(conversation: [:title])
  end
end
