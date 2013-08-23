require 'spec_helper'

describe Person do
  it 'acts as paranoid' do
    Person.count.should eql(0)
    Person.only_deleted.should be_empty

    person = FactoryGirl.create(:person)

    Person.count.should_not eql(0)

    person.destroy

    Person.count.should eql(0)
    Person.only_deleted.should_not be_empty
  end

  it "does not allow duplicat emails" do
    person = FactoryGirl.create(:person, email: "joe@example.com")
    person2 = FactoryGirl.build(:person, email: "joe@example.com")
    person2.should_not be_valid
  end

  describe 'by_office Scope' do
    let(:office_a_person) { FactoryGirl.create(:person) }
    let(:office_b_person) { FactoryGirl.create(:person) }

    it 'should return an ActiveRecord::Relation Class' do
      Person.by_office(office_a_person).should be_kind_of(ActiveRecord::Relation)
      Person.by_office(nil).should be_kind_of(ActiveRecord::Relation)
    end

    it 'should return people that belongs to that office' do
      Person.by_office(office_a_person.office).should include(office_a_person)
      Person.by_office(office_b_person.office).should include(office_b_person)
    end

    it 'should return all people when office is nil' do
      Person.by_office(nil).to_a.should eql(Person.all)
    end
  end

  describe '.employed_on_date with today as date' do
    let(:date) { Date.today }

    it 'includes someone without a start or end date' do
      employee = FactoryGirl.create(:person)
      Person.employed_on_date(date).should include(employee)
    end

    it 'includes someone whose end date is in the future' do
      employee = FactoryGirl.create(:person, end_date: 1.week.from_now)
      Person.employed_on_date(date).should include(employee)
    end

    it 'does not include someone whose end date is in the past' do
      non_employee = FactoryGirl.create(:person, end_date: 1.week.ago)
      Person.employed_on_date(date).should_not include(non_employee)
    end

    it 'does not include someone whose start date is in the future' do
      non_employee = FactoryGirl.create(:person, start_date: 1.week.from_now)
      Person.employed_on_date(date).should_not include(non_employee)
    end

    it 'does not include a person deleted in a paranoid way' do
      employee = FactoryGirl.create(:person)
      employee.destroy
      Person.employed_on_date(date).should be_empty
    end
  end

  describe '.overhead' do
    it 'includes people marked as unsellable' do
      employee = FactoryGirl.create(:person, unsellable: true)
      Person.overhead.should include(employee)
    end

    it 'does not include people marked as sellable' do
      employee = FactoryGirl.create(:person, unsellable: false)
      Person.overhead.should_not include(employee)
    end

    it 'does not include deleted employees' do
      employee = FactoryGirl.create(:person, unsellable: true)
      employee.destroy
      Person.overhead.should_not include(employee)
    end
  end

  describe '.billable' do
    it 'does not include people marked as unsellable' do
      employee = FactoryGirl.create(:person, unsellable: true)
      Person.billable.should_not include(employee)
    end

    it 'includes people marked as sellable' do
      employee = FactoryGirl.create(:person, unsellable: false)
      Person.billable.should include(employee)
    end

    it 'does not include deleted employees' do
      employee = FactoryGirl.create(:person, unsellable: false)
      employee.destroy
      Person.billable.should_not include(employee)
    end
  end

  describe '.unassignable_on_date by office' do
    let(:date) { Date.today }
    let(:project) { FactoryGirl.create(:project, :vacation) }
    let(:office_employee) { FactoryGirl.create(:person, unsellable: false) }
    let(:other_office_employee) { FactoryGirl.create(:person, unsellable: false) }

    before do
      FactoryGirl.create(:allocation, project: project, person: office_employee, start_date: 1.week.ago, end_date: Date.tomorrow)
      FactoryGirl.create(:allocation, project: project, person: other_office_employee, start_date: 1.week.ago, end_date: Date.tomorrow)
    end

    it 'should return unassignable people by office' do
      Person.unassignable_on_date(date, office_employee.office).should include(office_employee)
      Person.unassignable_on_date(date, office_employee.office).should_not include(other_office_employee)
    end
  end

  describe '.unassignable_on_date with today as date' do
    let(:date) { Date.today }
    let(:vacation) { FactoryGirl.create(:project, :vacation) }

    it 'includes someone allocated to vacation today' do
      employee = FactoryGirl.create(:person, unsellable: false)
      FactoryGirl.create(:allocation, person: employee, project: vacation, start_date: 1.week.ago, end_date: Date.tomorrow)
      Person.unassignable_on_date(date).should include(employee)
    end

    it 'includes them only once even if they are billed on two vacation projects' do
      employee = FactoryGirl.create(:person, unsellable: false)
      conference = FactoryGirl.create(:project, :vacation)
      FactoryGirl.create(:allocation, person: employee, project: vacation, start_date: 1.week.ago, end_date: Date.tomorrow)
      FactoryGirl.create(:allocation, person: employee, project: conference, start_date: 1.week.ago, end_date: Date.tomorrow)
      Person.unassignable_on_date(date).should include(employee)
      Person.unassignable_on_date(date).size.should eql(1)
    end

    it 'does not include someone allocated to a billable project today' do
      employee = FactoryGirl.create(:person, unsellable: false)
      project = FactoryGirl.create(:project, :billable)
      FactoryGirl.create(:allocation, person: employee, project: project, start_date: 1.week.ago, end_date: Date.tomorrow)
      Person.unassignable_on_date(date).should_not include(employee)
    end

    it 'does not include someone who is unsellable' do
      employee = FactoryGirl.create(:person, unsellable: true)
      FactoryGirl.create(:allocation, person: employee, project: vacation, start_date: 1.week.ago, end_date: Date.tomorrow)
      Person.unassignable_on_date(date).should_not include(employee)
    end

    it 'does not include someone who no longer works here' do
      former_employee = FactoryGirl.create(:person)
      FactoryGirl.create(:allocation, person: former_employee, project: vacation, start_date: 1.week.ago, end_date: Date.tomorrow)
      former_employee.update_attributes!(end_date: Date.yesterday)
      Person.unassignable_on_date(date).should_not include(former_employee)
    end
  end

  describe '.billing_on_date with -today- as value' do
    let(:date) { Date.today }
    let(:billable_project) { FactoryGirl.create(:project, :billable) }
    let(:employee) { FactoryGirl.create(:person) }

    it 'includes someone allocated to a billable project today' do
      FactoryGirl.create(:allocation, person: employee, project: billable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: true)
      Person.billing_on_date(date).should include(employee)
    end

    it 'includes the person only once, even if they are allocated to two different projects' do
      another_billable_project = FactoryGirl.create(:project, billable: true)
      FactoryGirl.create(:allocation, person: employee, project: billable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: true)
      FactoryGirl.create(:allocation, person: employee, project: another_billable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: true)
      Person.billing_on_date(date).should include(employee)
      Person.billing_on_date(date).size.should eql(1)
    end

    it 'does not include someone allocated to a billable project in an unbillable way' do
      FactoryGirl.create(:allocation, person: employee, project: billable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: false)
      Person.billing_on_date(date).should_not include(employee)
    end

    it 'does not include someone allocated to an unbillable project' do
      unbillable_project = FactoryGirl.create(:project, billable: false)
      FactoryGirl.create(:allocation, person: employee, project: unbillable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: false)
      Person.billing_on_date(date).should_not include(employee)
    end

    it 'does not include someone on vacation' do
      vacation = FactoryGirl.create(:project, :vacation)
      FactoryGirl.create(:allocation, person: employee, project: vacation, start_date: 1.week.ago, end_date: Date.tomorrow)
      Person.billing_on_date(date).should_not include(employee)
    end

    it 'does not include someone on vacation if they are also allocated to a billable project' do
      vacation = FactoryGirl.create(:project, :vacation)
      FactoryGirl.create(:allocation, person: employee, project: vacation, start_date: 1.day.ago, end_date: Date.tomorrow)
      FactoryGirl.create(:allocation, person: employee, project: billable_project, start_date: 1.week.ago, end_date: 1.week.from_now, billable: true)
      Person.billing_on_date(date).should_not include(employee)
    end

    it 'does include someone who is billing even though they normall do not' do
      overhead_employee = FactoryGirl.create(:person, unsellable: true)
      FactoryGirl.create(:allocation, person: overhead_employee, project: billable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: true)
      Person.billing_on_date(date).should include(overhead_employee)
    end

    it 'should be able to filter by office' do
      FactoryGirl.create(:allocation, person: employee, project: billable_project, start_date: 1.week.ago, end_date: Date.tomorrow, billable: true)
      Person.billing_on_date(date, employee.office).should include(employee)
      Person.billing_on_date(date, FactoryGirl.create(:office)).should_not include(employee)
    end
  end

  describe ".pto_requests" do
    let(:start_of_year) { Date.today.beginning_of_year }
    let(:end_of_year) { Date.today.end_of_year }
    let(:employee) { FactoryGirl.create(:person) }
    let(:billable_project) { FactoryGirl.create(:project, :billable) }
    let(:vacation_project) { FactoryGirl.create(:project, :vacation) }

    let!(:vacation_alloc) { FactoryGirl.create(:allocation, person: employee, project: vacation_project, start_date: 1.day.ago, end_date: Date.tomorrow) }
    let!(:billable_alloc) { FactoryGirl.create(:allocation, person: employee, project: billable_project, start_date: 1.week.ago, end_date: 1.week.from_now) }
    let!(:vacation_alloc_last_year) { FactoryGirl.create(:allocation, person: employee, project: vacation_project, start_date: 15.months.ago, end_date: 13.months.ago) }

    it 'includes allocations from this year that are vacatation' do
      employee.pto_requests.should include(vacation_alloc)
    end

    it 'should not include allocations from this year that are not vacation' do
      employee.pto_requests.should_not include(billable_alloc)
    end

    it 'should not include allocations from last year that are vacatation' do
      employee.pto_requests.should_not include(vacation_alloc_last_year)
    end
  end
end
