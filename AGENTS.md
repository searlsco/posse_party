# Handy tips

## Quick Browser Login for POSSE Party

1. Server is already running at http://localhost:3000
2. Enter `justin@searls.co` in the email field and submit. The password is usuall `foo`
3. If `foo` doesn't work, send a login email and then navigate to `http://localhost:3000/test/latest_email` to retrieve the login link. Follow the link to authenticate and continue testing.

## Running tests

- please always run with CI=true so that system tests run headlessly (unless trying to get screenshots or to debug a visual issue)
- full suite: ./script/test
- individual test: bin/rails test <testpath>[:linenbr]

# On this team, we've all agreed to ALWAYS do this:

If you struggle to do any of these, pause and ask for help.

- Always return a Struct when multiple values are needed by the caller
- Always use Struct `Result` (app/lib/result.rb) when there is a return value but success/failure info may be needed
- Always use struct `Outcome` (app/lib/outcome.rb) when the unit is a command that is only concerned with `message` and `success?`
- Always treat ActiveRecord models and controllers as configuration classes focused solely on configuring the framework
- Always introduce new POROs for behavior needed by a controller
- Always define the dependencies of POROs that implement app behavior in `app/lib/**`. If the PORO depends on other POROs, instantiate them as ivars in the constructor (without duplicatively accepting them as arguments, since Mocktail can inject without constructor-injection). Pass all runtime/domain/unit-of-work inputs to public methods as arguments, however, as opposed to assigning them to the instance
- Always extract repeated tailwind classes to a helper method so they are not duplicated
- Always implement styles in Tailwind 4 classes
- Always switch to keyword arguments when a method needs more than three parameters
- Always name tests as methods (e.g. `def test_this_or_that` over `test "this or that"`)
- Always use VCR (as opposed to Webmock or Mocktail) for tests of third-party servers. (We record VCR cassettes, then scrub secrets, then commit the sanitized cassette playback test.)


# On this team, we've all agreed to NEVER do these without checking with our pair first:

If you find yourself wanting to do any of these, pause what you're doing and ask for approval.

- Never add business logic to a Rails model or controller
- Never add attr_reader/attr_accessor/attr_writer
- Never accept any arguments in a PORO's `initialize` (no positional, keyword, defaults, or splats) and never inject collaborators via `initialize`
- Never repeat chunks of markup that could be factored as a partial
- Never add custom CSS or style attributes
- Never generate tailwind CSS classes, as Tailwind's JIT will discard them and they won't work. better to store multiple fully written-out class names in data structures or to be returned by methods when trying to clean up or allow for dynamism in a template
- Never write loops in tests
- Never introduce branching (if/else) in tests
- Never metaprogram in tests
- Never create empty initializers
- Never leave empty access modifiers (e.g. "private" with nothing beneath it)
- Never leave behind dead code for "backwards compatibility" or migration.

# Code style

Prefer functional styles that don't mutate variables or assign superfluous local variables. Inline and compact logic as much as possible so that the shape of data is emphasized over the step-by-step procedure:

```ruby
def validate_registration(user, params, errors)
  ## GOOD
  [
    ("Registration is invite-only." if User.exists? && !Invite.open.for_email(params[:email]).exists?),
    ("Password can't be blank" if params[:password].blank?),
    ("Password confirmation can't be blank" if params[:password_confirmation].blank?)
  ].compact

  ## BAD
  # errors = Array(errors)

  # if User.exists?
  #   invite_exists = Invite.open.for_email(params[:email]).exists?
  #   errors << "Registration is invite-only." unless invite_exists
  # end

  # errors << "Password can't be blank" if params[:password].blank?
  # errors << "Password confirmation can't be blank" if params[:password_confirmation].blank?

  # errors
end
```
