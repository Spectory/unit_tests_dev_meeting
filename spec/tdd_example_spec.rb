require './spec/spec_helper'
require './src/tdd_example'

# Lets Say this is our Task:
#
# As PO I would like to send invitations by email.
#
# DOD:
#   - send invitation to a given email address
#   - each invitation should use a unique token.
#   - have only 3 attempts for the same email.
#

# try to do it by your own, without unit tests.

# now lets solve that the TDD way!
# we think about what we need, setup a test case & an expected result. than write the actual code.
# here we go!

# For name space sake, we better wrap the functionally in a module, lets call that 'InviteSender'
describe 'InviteSender' do
  # ignore this block for now, we talk about it later...
  before do
    InviteSender::EMAIL_COUNTER.clear
  end

  # according to the US, we are going to handle email address as inputs.
  # its always a good idea to make sure input is valid before even trying any thing else.
  # lets make sure we can do differentiate between bad/good emails
  describe 'valid_email?' do
    valid_emails = %w(some@email.com some@email.org some@email.co.il)
    invalid_emails = %w(someemail.com @email.org some@.co.il)
    it 'when emails are valid' do
      valid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be true }
    end
    it 'when emails are invalid' do
      invalid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be false }
    end
  end

  # great. the US also states each email should have a unique token.
  # lets make sure we can to that.
  describe 'email_msg' do
    # lets define how a email msg looks like. well, its a pair of email address & a token.
    email = 'some@email.com'
    describe 'email_msg structure' do
      msg = nil
      before do
        msg = InviteSender.send(:email_msg, email)
      end

      it 'should hold given email' do
        expect(msg[:email]).to eq email
      end

      it 'should hold a String token' do
        expect(msg[:token].is_a? String).to be true
      end
    end

    # ok, now we know how a email_msg looks like, lets deal with the token uniqueness
    it 'each email_msg should have a uniqe token' do
      emails = (1..100).map { |n| "email_#{n}@domain.com" }
      emails_msgs = emails.map { |e| InviteSender.send(:email_msg, e) }
      tokens = emails_msgs.map { |msg| msg[:token] }
      uniqe_tokens = tokens.uniq
      expect(uniqe_tokens.size).to eq(emails.size)
    end
  end

  # excellent! looks like we are ready to send the actual invitations
  describe 'send_invite_to' do
    # we need to make sure each email only gets 3  send attempts.
    # so we need to come up with a way to count sent attempts for each email address.
    # mmm... how should it behave? when ever we send an email, its counter should increment.
    # but notice! we don't want to count invites from other tests! therefore we need to rest this counter before each test (now the block at line 8 make scene, ha!)
    describe 'attempts_counter' do
      email = 'some@email.com'
      it 'should hash email address to an int' do
        expect(InviteSender::EMAIL_COUNTER[email]).to be nil
        InviteSender.send_invite_to email
        expect(InviteSender::EMAIL_COUNTER[email]).to be 1
        InviteSender.send_invite_to email
        expect(InviteSender::EMAIL_COUNTER[email]).to be 2
      end
    end

    # Awesome! now lets make sure we allow only 3 attempts.
    describe 'attempts limit' do
      email = 'some@email.com'
      it 'when less than 3 attempts' do
        3.times { expect(InviteSender.send_invite_to email).to be true }
      end
      it 'when more than 3 attempts' do
        3.times { expect(InviteSender.send_invite_to email).to be true }
        expect(InviteSender.send_invite_to email).to be false
      end
    end
  end

  # that looks damn AWESOME, now lets make sure it all works together. look how simple it is
  it 'when email is invalid' do
    ivalid_email = 'aaaa'
    expect(InviteSender.send_invite_to ivalid_email).to be false
  end

  it 'when email is valid' do
    email = 'some@email.com'
    3.times { expect(InviteSender.send_invite_to email).to be true }
    3.times { expect(InviteSender.send_invite_to email).to be false }
  end
end

# Great success!!!
# a few things to talk about:
# - the actual code is much shorter than the unit tests.
# - it took me about 1.5 hour to do it all, including comments and all.
# - reading the tests code really describes the InviteSender behavior. thats great documentation for the future
# - compare it to your non TDD code it you wrote it, which is better? more robust? more flexible?
#
