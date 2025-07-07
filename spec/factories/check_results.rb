FactoryBot.define do
  factory :check_result do
    address { nil }
    status { 1 }
    response_time_ms { 1 }
    checked_at { "2025-07-06 14:39:54" }
    message { "MyString" }
  end
end
