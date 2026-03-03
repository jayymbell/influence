class ConversationPolicy < ApplicationPolicy
  # Users can only manage their own conversations

  def index?
    true
  end

  def show?
    owner?
  end

  def create?
    true
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  # Custom action: send a message in the conversation
  def send_message?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owner?
    record.user_id == user.id
  end
end
