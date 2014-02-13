module DateRangeHelper
  def with_week_days(days_count=21, &block)
    date_range = ((Date.today)..(days_count.days.from_now.to_date))

    date_range.to_a.each do |date|
      unless date.saturday? || date.sunday?
        yield date
      end
    end
  end

  def week_days(month=nil)
    month ||= Date.today
    (month.beginning_of_month..month.end_of_month).reject do |date|
      date.saturday? || date.sunday?
    end
  end

  def week_days_between(start_date, end_date)
    Range.new(start_date, end_date)
    .reject { |d| d.saturday? || d.sunday? }
  end

  def with_week_days_in(month=nil, &block)
    week_days(month).each(&block)
  end
end
