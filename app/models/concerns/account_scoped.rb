module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account
    validates :account, presence: true

    before_validation :set_default_account, on: :create

    scope :for_current_account, -> {
      acct = Current.account
      acct ? where(account_id: acct.id) : none
    }

    private

      def set_default_account
        self.account ||= Current.account
      end

  end
end