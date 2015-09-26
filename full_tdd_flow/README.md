Tdd Flow Example
===========

Lets Say this is our Task:

As PO I would like to send invitations by email.
DOD:
  - send invitation to a given email address
  - each invitation should use a unique token.
  - have only 3 attempts for the same email.
  - assume there is a Util module that sends that actual emails

now lets solve that the TDD way!
 1. think about what we need
 2. setup a test case & an expected result
 3. write the actual code.
 4. repeat till its done.

here we go!

----

For name-space sake, we better wrap the functionally in a module, lets call that 'InviteSender', and write the unit tests for it

```ruby
describe 'InviteSender' do
end
```

according to the US, we are going to handle email address as inputs.
its always a good idea to make sure input is valid before even trying any thing else.
lets make sure we can do differentiate between bad/good emails

```ruby
  describe 'valid_email?' do
    valid_emails = %w(some@email.com some@email.org some@email.co.il)
    invalid_emails = %w(someemail.com @email.org some@.co.il)
    describe 'when emails are valid' do
      it 'should return true' do
        valid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be true }
      end
    end
    describe 'when emails are invalid' do
      it 'should return false' do
        invalid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be false }
      end
    end
  end
```

new lets write the actual code that passes the tests

```ruby
  module Utils
    VALID_EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  end

  def valid_email?(email)
    return (email =~ Utils::VALID_EMAIL_REGEX) == 0
  end

```

all tests pass, excellent!

---

the US also states each email should have a unique token. lets make sure we can to that. First lets define how a email msg looks like. well, its a pair of email address & a token.

```ruby
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
```

and the code

```ruby
  def email_msg(email)
    return { email: email, token: '' }
  end
```

ok, now we know how a email_msg looks like, lets deal with the token uniqueness

```ruby
  it 'should have a uniqe token' do
    emails = (1..100).map { |n| "email_#{n}@domain.com" }
    emails_msgs = emails.map { |e| InviteSender.send(:email_msg, e) }
    tokens = emails_msgs.map { |msg| msg[:token] }
    uniqe_tokens = tokens.uniq
    expect(uniqe_tokens.size).to eq(emails.size)
  end
```

well this is pretty easy to do, just modify email_msg method

```ruby
  def email_msg(email)
    return { email: email, token: SecureRandom.hex }
  end
```

holly crap that worked! 

Looks like all our helper units behave as we expect them. Lets think how to send the actual invitations.

---

We need to make sure each email only gets 3  send attempts.
so we need to come up with a way to count sent attempts for each email address.
mmm... how should it behave? whenever we send an email, its counter should increment.
**but notice! we don't want to count invites from other tests!** therefore we need to rest this counter before each test, lets add that as a before action for each test.

```ruby
  before do
    InviteSender::EMAIL_COUNTER.clear
  end

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
```

and the code

```ruby
  EMAIL_COUNTER = {}

  def send_invite_to(email)
    EMAIL_COUNTER[email] = 0 unless EMAIL_COUNTER[email]
    EMAIL_COUNTER[email] += 1
  end
```

Awesome! now lets make sure we allow only 3 attempts.

```ruby
  describe 'attempts limit' do
    email = 'some@email.com'
    describe 'when less than 3 attempts' do
      it 'should return true' do
        3.times { expect(InviteSender.send_invite_to email).to be true }
      end
    end
    describe 'when more than 3 attempts' do
      it 'should return false' do
        3.times { expect(InviteSender.send_invite_to email).to be true }
        expect(InviteSender.send_invite_to email).to be false
      end
    end
  end
```

and modify the code

```ruby
  def send_invite_to(email)
    return false unless valid_email? email
    EMAIL_COUNTER[email] = 0 unless EMAIL_COUNTER[email]
    EMAIL_COUNTER[email] += 1
    return false if EMAIL_COUNTER[email] > 3
    Utils.send_email email_msg(email)
  end
```

Lets run the tests, they all pass but... AHH! we called the Util.send_email method! this sent real emails to some@email.com.
running production code at unit tests is a big NO NO!

we should stub Util.send_email method, and mock its expected return value

```ruby
  before do
    InviteSender::EMAIL_COUNTER.clear
    mock_util_send_email(true)
  end

  def mock_util_send_email(response)
    allow(Utils).to receive(:send_email).and_return(response)
  end
```

well thats better.

---

almost done, lets wrap it all up from top to bottom.

```ruby
  it 'when email is invalid' do
    ivalid_email = 'aaaa'
    expect(InviteSender.send_invite_to ivalid_email).to be false
  end

  it 'when email is valid' do
    email = 'some@email.com'
    3.times { expect(InviteSender.send_invite_to email).to be true }
    3.times { expect(InviteSender.send_invite_to email).to be false }
  end
```

if those last test pass, we did a fine job. Great success!!!

---

Summery
=====

Tips & notes:
  - the actual code is much shorter than the unit tests.
  - it took about 1 hour to do it all.
  - reading the tests code really describes the InviteSender behavior. thats great documentation for the next poor fellow that need to use/debug our code.
  - how does our coverage report look like?
  - what will happen if we delete all unit tests and leave only the last two?
  - what does it mean to have 'well covered' code?

Lets see if it matches a few 'unit tests golden rules':

1. don't assert or verify anything that's been asserted / verified in another test refer only to the core behavior under test.
2. code architecture must support independent unit-testing
3. mock out all external services and state
4. Avoid having common setup code that runs at the beginning of lots of unrelated tests

Compare this code to your non TDD code if you wrote one

  - which is better?
  - more robust?
  - more flexible?
  - how did you check your code really works?
  - how long did it take you to write it?
  - did you cover different scenarios, or only the golden one?
  - which is easier to debug?
