FactoryBot.define do
  factory :address do
    name { "MyString" }
    address_type { 1 }
    url { "MyString" }
    ip { "MyString" }
    port { 1 }
    enabled { false }
    user { nil }
  end
end
