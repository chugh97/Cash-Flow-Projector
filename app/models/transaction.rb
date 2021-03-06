class Transaction < ActiveRecord::Base
  extend DateValidator
  include DateRangeScopes

  validates_date :date
  validate :validate_balanced

  belongs_to :user
  belongs_to :source, :polymorphic => true
  has_many :ledger_entries, :dependent => :destroy
  accepts_nested_attributes_for :ledger_entries

  after_initialize :set_defaults, :if => :new_record?

  after_save :propogate_date_to_ledger_entries
  before_save :update_amount

  def balanced?
    sum_credits = ledger_entries.map(&:credit).reduce(:+)
    sum_debits = ledger_entries.map(&:debit).reduce(:+)
    sum_credits  == sum_debits
  end

  def move_money(from, to, amount)
    ActiveRecord::Base.transaction do
      from.decrease(amount, self.date, self)
      to.increase(amount, self.date, self)
      self.amount = amount
      save!
    end
  end

  private

  def update_amount
    self.amount = ledger_entries.map(&:credit).reduce(:+) if ledger_entries.present?
  end

  def validate_balanced
    errors.add(:base, I18n.t('errors.transaction.unbalanced_transaction')) unless balanced?
  end

  def set_defaults
    self.date ||= Date.today
    self.reference ||= ''
  end

  def propogate_date_to_ledger_entries
    ActiveRecord::Base.transaction do
      ledger_entries.where(:transaction_id => self.id).update_all(:date => self.date)
      ledger_entries.reload
    end
  end
end
