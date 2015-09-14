module Utils
  VALID_EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  def self.send_email(email_msg)
    # assume this sends the actual email, and return true when done.
    puts 'this should never print while you run your tests'
    return true
  end
end

module InviteSender
  EMAIL_COUNTER = {}

  module_function

  def send_invite_to(email)
    return false unless valid_email? email
    EMAIL_COUNTER[email] = 0 unless EMAIL_COUNTER[email]
    EMAIL_COUNTER[email] += 1
    return false if EMAIL_COUNTER[email] > 3
    Utils.send_email email_msg(email)
  end

  private

  module_function

  def valid_email?(email)
    return (email =~ Utils::VALID_EMAIL_REGEX) == 0
  end

  def email_msg(email)
    return { email: email, token: SecureRandom.hex }
  end
end
