# Unit Tests 101

Unit testing refers to the practice of testing functions and areas of our code.
When done right, it affords several benefits:

1. Discovers bugs early. when tests fails, some modules are not working properly, which usually means bugs.
2. Makes refactoring easier. When you need to improve the unit, you still keep its general behavior, so the unit tests should pass before/after the code change.
3. Documentation - Text docs are often neglected and not updated as the code grows. Unit tests supply a small examples for our unit in action, that is always up to date.
4. Design - Its hard to write unit tests for code that is badly designed since the units are too complex. Unit tests force us to keep simpler code design.

At this blog post we'll cover the last two by practical examples. We'll use Ruby & Angular, while following BDD approach.

-----------------------------------------------------------------------------------------------------------------------
## Behavior Driven Development Example

Lets Say this is our Task:
```
As Product Owner, I would like to send invitations by email.
Definition of done:
  - Send invitation to a given email address.
  - Each invitation should use a unique token.
  - Have only 3 attempts for the same email.
  - Assume there is a Util module that sends that actual emails
```

Now lets solve that with BDD:
 1. Think about what we need
 2. Setup a test case & an expected result
 3. Write the actual code.
 4. Repeat till its done.

Here we go!

For name-space sake, we better wrap the functionally in a module, lets call that 'InviteSender', and write the unit tests for it

```ruby
describe 'InviteSender' do
end
```

As describe at task, we are going to handle email address as inputs.
Its always a good idea to make sure input is valid before even trying any thing else.
Lets make sure we can do differentiate between bad/good emails

```ruby
  describe 'valid_email?' do
    context 'when emails are valid' do
      valid_emails = %w(some@email.com some@email.org some@email.co.il)
      it 'should return true' do
        valid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be true }
      end
    end
    context 'when emails are invalid' do
      invalid_emails = %w(someemail.com @email.org some@.co.il)
      it 'should return false' do
        invalid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be false }
      end
    end
  end
```

Now that we defined the unit behavior lets write the actual code that passes the tests

```ruby
  module Utils
    VALID_EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  end

  def valid_email?(email)
    return (email =~ Utils::VALID_EMAIL_REGEX) == 0
  end

```

The task also states each email should have a unique token. Lets make sure we can to that. First, define how we pair email addresses & tokens.

```ruby
describe 'email_token_pair' do
  email = 'some@email.com'
  describe 'email_token_pair structure' do
    msg = nil
    before do
      msg = InviteSender.email_msg(email)
    end

    it 'should hold given email' do
      expect(msg[:email]).to eq email
    end

    it 'should hold a String token' do
      expect(msg[:token].is_a? String).to be true
    end
  end
end
```

And the code

```ruby
  def email_msg(email)
    return { email: email, token: '' }
  end
```

Ok, we know how a email_msg looks like, lets deal with the token uniqueness

```ruby
  it 'should have a uniqe token' do
    emails = (1..100).map { |n| "email_#{n}@domain.com" }
    emails_msgs = emails.map { |e| InviteSender.send(:email_msg, e) }
    tokens = emails_msgs.map { |msg| msg[:token] }
    uniqe_tokens = tokens.uniq
    expect(uniqe_tokens.size).to eq(emails.size)
  end
```

Well this is pretty easy to do, just modify email_msg method

```ruby
  def email_msg(email)
    return { email: email, token: SecureRandom.hex }
  end
```

Looks like all our helper units behave as we expect them. Lets think how to send the actual invitations.

We need to make sure each email only gets 3  send attempts.
So we need to come up with a way to count send attempts for each email address.

Mmm... How should it behave? Whenever we send an email, its counter should increment.
**but notice! we don't want to count invites from other tests!**, therefore we need to rest this counter before each test. Lets add that as a before action for each test.

```ruby
  before do
    InviteSender::EMAIL_COUNTER.clear
  end

  describe 'EMAIL_COUNTER' do
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

The code:

```ruby
  EMAIL_COUNTER = {}

  def send_invite_to(email)
    EMAIL_COUNTER[email] = 0 unless EMAIL_COUNTER[email]
    EMAIL_COUNTER[email] += 1
  end
```

Awesome! Now lets make sure we allow only 3 attempts.

```ruby
  describe 'send_invite_to' do
    email = 'some@email.com'
    context 'when less than 3 attempts' do
      it 'should return true' do
        3.times { expect(InviteSender.send_invite_to email).to be true }
      end
    end
    context 'when more than 3 attempts' do
      it 'should return false' do
        3.times { expect(InviteSender.send_invite_to email).to be true }
        expect(InviteSender.send_invite_to email).to be false
      end
    end
  end
```

And modify the code

```ruby
  def send_invite_to(email)
    return false unless valid_email? email
    EMAIL_COUNTER[email] = 0 unless EMAIL_COUNTER[email]
    EMAIL_COUNTER[email] += 1
    return false if EMAIL_COUNTER[email] > 3
    Utils.send_email email_msg(email)
  end
```

Lets run the tests, they all pass, but... AHH! We called the Util.send_email method! this sent real emails to some@email.com.
Running production code at unit tests is a big NO NO!

We should **stub** Util.send_email method, and **mock** its expected return value

```ruby
  before do
    InviteSender::EMAIL_COUNTER.clear
    mock_util_send_email(true)
  end

  def mock_util_send_email(response)
    allow(Utils).to receive(:send_email).and_return(response)
  end
```

Almost done. Lets wrap it all up from top to bottom.

```ruby
  context 'when email is invalid' do
    ivalid_email = 'aaaa'
    it 'should return false' do
      expect(InviteSender.send_invite_to ivalid_email).to be false
    end
  end

  context 'when email is valid' do
    email = 'some@email.com'
    it 'should return false' do
      3.times { expect(InviteSender.send_invite_to email).to be true }
      3.times { expect(InviteSender.send_invite_to email).to be false }
    end
  end
```

If those last test pass, we did a fine job. Great success!

-----------------------------------------------------------------------------------------------------------------------

## Tests as documentation

Unit tests can improve not only your code logic, but also make it clearer to other developers.
Unit tests are great tool for the documentation. Unlike text docs, unit tests keep the documentation up to date - when the code changes, the tests will fail, indicating the docs are outdated.

Here is an example where we test the unit 'valid_email?' - a function that checks if a given string follows an email format:

```ruby
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
```

That will work. Other developers can understand which email formats are valid and which are not.

But notice how in order to fully understand what the valid_email? methods does, we must understand the code inside the *it* blocks. Sometimes that code is might not be very simple & clear.
We can help our fellow developers. A nice way to achieve that is by linking the describe & it blocks into an English sentence.

 - *describe* block is where we introduce our test unit / subject, and add more details
 - *context* block is where we build the test setup / scenario.
 - *it* block is the actual test, what we expect to happen.

```ruby
describe 'valid_email?' do
  context 'when emails are valid' do
    valid_emails = %w(some@email.com some@email.org some@email.co.il)
    it 'should return true' do
      valid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be true }
    end
  end
  context 'when emails are invalid' do
    invalid_emails = %w(someemail.com @email.org some@.co.il)
    it 'should return false' do
      invalid_emails.each { |e| expect(InviteSender.send(:valid_email?, e)).to be false }
    end
  end
end
```
Linking the blocks gives us a nice explanation of what the method is expected to do:
```
valid email?, when emails are valid, should return true.
valid email?, when emails are invalid, should return false.
```

-----------------------------------------------------------------------------------------------------------------------

### Code Design:

We need a controller that gets an array of numbers form server, then store it & its accumulative value on scope. For simplicity, lets assume *ajaxService* handles our http actions, and returns a promise obj.

This will do the trick

```js
angular.module('app').controller('mainCtl', function ($scope, ajaxService) {

  function processArrFromServer() {
    ajaxService('GET', 'server_url/arrays/3').then(function processRespose(response) {
      var arr = [];
      var acc = 0;
      //assume here we extract data from response into arr...
      $scope.arr = arr;
      $scope.arr.forEach(function (num) {
        acc += num;
      });
      $scope.acc = acc;
    });
  }

  $scope.init = function () {
    processArrFromServer();
  };
```

init function does 3 things:
  - get data from the server
  - process the response into $scope.arr
  - accumulate the arr into $scope.acc

In order to test this ctl, we must test init, and we must mock the http response.

We can do better by writing code that is easier to test.
Lets do it again, this time however, we follow the *'each function does one thing'* rule.

```javaScript
angular.module('app').controller('mainCtl', function ($scope, ajaxService) {
  var self = this;

  self.accumulateArr = function () {
    var acc = 0;
    $scope.arr.forEach(function (num) {
      acc += num;
    });
    return acc;
  };

  self.processRespose = function (response) {
    var arr = [];
    //assume here we extract data from response into arr...
    $scope.arr = arr;
    self.accumulateArr();
  };

  $scope.init = function () {
    ajaxService('GET', 'server_url/arrays/3').then(self.processRespose);
  };
});
```

init function still does the same 3 things:
  - Get data from the server
  - Process the response into $scope.arr
  - Accumulate the arr into $scope.acc

We did 2 things here:
 - Break the logical flow into steps, each function responsible for a single step. Calling init triggers the flow.
 - Only init is needed at our html view. We want to avoid placing other functions on the $scope. So we place the 'helper functions' on the controller object (self). This allows us to get access to the functions while running unit tests.

This architecture gives us much more flexibility. It allows us to choose what to test, and what not to pretty easily.
  - In order to test accumulateArr, we just need to set $scope.arr to some value.
  - In order to test processRespose, we can pass it a general response json.
  - In order to test init, we must mock the http request.

Notice that we can can get a pretty nice code coverage **without testing init at all**.
