require 'spec_helper'
require 'securerandom'

describe 'booking a visit', type: :feature do
  let(:prisoner) do
    # Trivia: George Best spent 7 days imprisoned in Pentonville for driving
    # under alcohol and assault [wikipedia]
    Prisoner.new(
      'George', 'Best',
      Date.parse('1970-01-01'), # Actually 1946-05-22
      'A1234BC',
      'Pentonville'
    )
  end

  let(:visitor) do
    Visitor.new(
      'Peter', 'Sellers',
      Date.parse('1925-09-08'),
      "#{SecureRandom.uuid}@example.com",
      '0123456789'
    )
  end

  it 'is possible to make a booking' do
    visit 'http://localhost:4000/en/request'

    expect(page).to have_content 'visiting'

    fill_in_prisoner_step(prisoner)
    click_button 'Continue'

    expect(page).to have_content 'Your details'

    fill_in_visitor_step(visitor)
    click_button 'Continue'

    expect(page).to have_content 'When do you want to visit?'

    fill_in_slots_step
    click_button 'Continue'

    expect(page).to have_content 'Check your request'

    click_button 'Send request'

    expect(page).to have_content 'Your request is being processed'
    expect(page).to have_content prisoner.prison
    expect(page).to have_content visitor.email

    # Helpful for debugging
    # save_screenshot('confirmation.png')

    # Fetch 'booking requested' email sent to prisoner
    # Tends to take ~ 2s locally for emails to be delivered and available via
    # API, so being generous to avoid false positives
    emails = retry_for(10, ->(emails) { emails.any? }) {
      Mailtrap.instance.search_messages(visitor.email)
    }
    # Since the email is unique only a single email should have been returned
    expect(emails.size).to eq(1)
    email = emails.first
    status_url = email.capybara.find_link('visit status page')[:href]

    # Extract visit_id for use later
    visit_id = status_url.split('/').last

    # Status page
    visit status_url
    expect(page).to have_content 'Your visit is not booked yet'
  end
end
