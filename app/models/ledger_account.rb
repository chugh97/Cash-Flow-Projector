class LedgerAccount < ActiveRecord::Base
  belongs_to :user

  has_many :ledger_entries, :dependent => :destroy
  has_many :balance_corrections, :dependent => :destroy

  before_destroy :delete_account_validation
  validate :control_name_restrictions

  default_scope -> {order(:name => :asc)}

  def self.control_account(name)
    where(:control_name => name).first
  end

  def debit(amount, date, transaction = nil)
    ledger_entries.create(:debit => amount, :date => date, :transaction => transaction)
  end

  def credit(amount, date, transaction = nil)
    ledger_entries.create(:credit => amount, :date => date, :transaction => transaction)
  end

  def increase(amount, date, transaction = nil)
    debit(amount, date, transaction)
  end

  def decrease(amount, date, transaction = nil)
    credit(amount, date, transaction)
  end

  # return the balance at the start of a given date, default to tomorrow to to get up to date balance
  def balance(date=Date.tomorrow)
    ledger_entries.before_date(date).sum(:debit) - ledger_entries.before_date(date).sum(:credit)
  end


  # return the bank activity for the specified date
  def activity(date)
    ledger_entries.for_date(date).sum(:debit) - ledger_entries.for_date(date).sum(:credit)
  end

  # return daily balances for a date range...
  def daily_balances(start_date, end_date)
    balance = balance(start_date)

    data = execute_sql(daily_balances_sql(start_date, end_date))

    balances = Array.new
    ((start_date)..(end_date)).each do |date|
      delta = if data[date].present?
                   delta = data[date]['activity'].to_d
                 else
                   0.00
                 end
      balances << {:date => date, :balance => balance, :activity => delta }
      balance += delta
    end
    balances
  end

  def is_control_account?
    control_name.present?
  end

  private

  def delete_account_validation
    if is_control_account?
      errors.add(:base, 'cannot delete a control account')
      return false
    end
  end

  def control_name_restrictions
    if persisted? && control_name_changed?
      errors.add(:base, 'cannot change control name')
      return false
    end
  end

  def daily_balances_sql(start_date, end_date)
    sql = "select date, sum(debit) - sum(credit) as activity "
    sql +="from ledger_entries where ledger_account_id = #{self.id} "
    sql +="and (date >= Date('#{start_date}') AND date <= Date('#{end_date}')) "
    sql +="group by date"
  end
  def execute_sql(sql)
    results = ActiveRecord::Base.connection.select_all(sql)
    transform_data_to_hash(results)
  end

  def transform_data_to_hash(data_set)
    hash = {}
    data_set.each do |item|
      key = Date.parse(item['date'])
      hash[key] = item
    end
    hash
  end
end
