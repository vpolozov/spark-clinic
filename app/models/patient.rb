class Patient < ApplicationRecord
  include AccountScoped
  has_many :observations, dependent: :destroy

  validates :external_id, presence: true
  validates :name, presence: true
  validates :external_id, uniqueness: { scope: :account_id }
end
