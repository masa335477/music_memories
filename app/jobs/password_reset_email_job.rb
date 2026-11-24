class PasswordResetEmailJob < ApplicationJob
  self.log_arguments = false

  def perform(email)
    user = User.find_by(email: email)
    return unless user

    PasswordsMailer.with(user: user).reset.deliver_now
  end
end
