require 'spec_helper'

describe Api::V1::OpportunitiesController do
  
  let(:person) {FactoryGirl.create(:person)}
  let(:another_person) { FactoryGirl.create(:person, email: 'another_person@neo.com') }
  let(:company) { FactoryGirl.create(:company) }

  before do
    4.times do
      FactoryGirl.create(:opportunity, person: person)
    end

    6.times do
      FactoryGirl.create(:opportunity, person: another_person)
    end

    sign_in :user, person.user
  end

  it 'should get all opportunities' do
    get :index

    opportunities = JSON.parse(response.body)
    opportunities["opportunities"].size.should eq (10)
    opportunities["opportunities"].select{ |opportunity| opportunity["owner"]["id"] == person.id }.size.should eq(4)
  end

  describe 'OpportunityNotes' do
    before do
      4.times do
        FactoryGirl.create(:opportunity_note, opportunity: Opportunity.where(person_id: person.id).first)
      end
    end

    it 'should include notes' do
      get :index

      opportunities = JSON.parse(response.body)
      opportunities["opportunities"].first["opportunity_notes"].size.should eq(4)
      opportunities["opportunities"].first["opportunity_notes"].first["detail"].should eq(OpportunityNote.first.detail)
    end
  end

  describe 'create an opportunity' do
    it 'should create with default values' do
      post :create

      opportunity = JSON.parse(response.body)
      opportunity['opportunity']["owner"]["name"].should eq(person.name)
      opportunity['opportunity']["stage"].should eq('new')
      opportunity['opportunity']["confidence"].should eq('warm')
      opportunity['opportunity']["title"].should eq("#{person.name}'s new opportunity")
    end

    describe 'contacts' do
      let(:contact) { FactoryGirl.create(:contact, company: company) }

      it 'should use an existent contact with company' do
        post :create, { opportunity: {company: {id: company.id}, contact: {name: contact.name, email: contact.email}} }

        opportunity = JSON.parse(response.body)
        opportunity['opportunity']["company"]["name"].should eq(company.name)
        opportunity['opportunity']["contact"]["name"].should eq(contact.name)
        opportunity['opportunity']["contact"]["email"].should eq(contact.email)
      end
    end
  end
  
  it 'update an opportunity' do
    put :update, { id: Opportunity.all.last.id, opportunity: { company_name: 'acme inc', confidence: 'warm', title: 'ux workshop', person_id: another_person.id } }

    opportunity = JSON.parse(response.body)
    opportunity["owner"]["name"].should eq(another_person.name)
    opportunity["stage"].should eq('new')
    opportunity["confidence"].should eq('warm')
    opportunity["title"].should eq("ux workshop")
  end

  it 'should allow to destroy' do
    delete :destroy, id: Opportunity.all.first.id
    response.status.should eq(200)
    Opportunity.all.count.should eq(9)
  end
end
