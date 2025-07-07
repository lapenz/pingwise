FactoryBot.define do
  factory :endpoint do
    name { "MyString" }
    endpoint_type { 1 }
    url { "MyString" }
    ip { "MyString" }
    port { 1 }
    status { 1 }
    enabled { false }
    user { nil }
  end
end
