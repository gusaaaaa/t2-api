class Person < ActiveRecord::Base
  acts_as_paranoid
  attr_accessible :name, :notes, :email, :unsellable, :office, :office_id, :start_date, :end_date

  has_many :allocations
  belongs_to :office
  belongs_to :project

  scope :employed_on_date, lambda { |d| where("start_date is NULL or start_date < ?",d).where("end_date is NULL or end_date > ?", d) }
  scope :currently_employed, lambda { employed_on_date(Date.today) }
  scope :overhead, where(unsellable: true)
  scope :billable, where(unsellable: false)

  def self.unassignable_today
    # Unsellable = ALWAYS overhead (e.g. the CEO)
    # Unassignable = Usually available to be assigned, but out on vacation or something like that
    eligible_employees = billable.currently_employed
    Allocation.today.unassignable.map(&:person).select{|p| eligible_employees.include?(p)}.uniq
  end

  def self.billing_today
    on_vacation = unassignable_today
    Allocation.today.billable.assignable.map(&:person).reject{|p| on_vacation.include?(p)}.uniq
  end

  def pto_requests
    allocations.this_year.vacation
  end
end
