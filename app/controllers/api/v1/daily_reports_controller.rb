class Api::V1::DailyReportsController < Api::V1::BaseController

  # GET: /api/v1/daily_reports/YYYYMMDD
  def show
    date = Date.strptime params[:date], '%Y%m%d'
    render json: DailyReport.on_date(date), serializer: DailyReportSerializer
  end
end
