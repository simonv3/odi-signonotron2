FactoryGirl.define do
  factory :supported_permission, aliases: [:non_delegatable_supported_permission] do
    association :application, factory: :application
  end

  factory :delegatable_supported_permission, parent: :supported_permission do
    delegatable true
  end
end