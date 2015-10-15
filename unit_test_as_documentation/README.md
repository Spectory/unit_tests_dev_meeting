Tests as documentation
---------------------

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

But notice how in order to fully understand what the valid_email? methods does, we must understand the code inside the *it* blocks. Sometimes that code is not very simple & clear.
We can help our fellow developers. A nice way to achieve that is by linking the describe & it blocks into an English sentence.

 -*describe* block is where we introduce our test unit / subject, and add more details
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
Linking the blocks gives us:
```
valid email?, when emails are valid, should return true.
valid email?, when emails are invalid, should return false.
```
