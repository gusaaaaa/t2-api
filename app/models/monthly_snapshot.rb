require 'date_range_helper'

# TODO: half-days are not accounted for
class MonthlySnapshot < ActiveRecord::Base

  include DateRangeHelper

  belongs_to :office

  scope :by_date, lambda {|date| where(snap_date: date.beginning_of_month) }
  scope :by_office_id, lambda {|office_id| office_id ? where(office_id: office_id) : where(false) }

  validates :snap_date, uniqueness: { scope: :office }

  def self.on_date!(date, office_id=nil)
    where(snap_date: date.beginning_of_month, office_id: office_id).first_or_initialize.tap do |snap|
      snap.calculate
      snap.save!
    end
  end

  def office
    oid = read_attribute(:office_id)
    oid.present? ? Office.find(oid) : Office::SummaryOffice.new
  end

  def self.one_per_month(office_id=nil)
    MonthlySnapshot.order("snap_date ASC").where(office_id: office_id)
  end

  def self.today!(office_id=nil)
    on_date!(Date.today, office_id)
  end

  def self.next_month!(office_id=nil)
    on_date!(Date.today.advance(months: 1), office_id)
  end

  def calculate
    reset_aggregates
    with_week_days_in(snap_date) do |date|
      Snapshot.on_date!(date, office_id: office_id).tap do |snapshot|
        self.billing_days += snapshot.billing.to_fte
        self.assignable_days += snapshot.assignable.to_fte
      end
    end
    self.utilization = assignable_days.zero? ? 0.0 : (billing_days/assignable_days * 100)
  end


  private

  def reset_aggregates
    self.billing_days    = 0.0
    self.assignable_days = 0.0
  end

end
