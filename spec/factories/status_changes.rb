FactoryBot.define do
  factory :status_change do
    endpoint { nil }
    status { 1 }
    response_time_ms { 1 }
    checked_at { "2025-07-06 14:51:43" }
    message { "MyString" }
  end
end
