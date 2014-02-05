class OpportunityContext

  def self.all
    persons = Person.where(role: ['Business Development', 'Principal', 'Managing Director', 'General & Administrative'])
    offices = Office.where("slug NOT SIMILAR TO '(dublin|headquarters|archived)'")
    CrmData.new(Opportunity.all, persons, offices, Company.all, Contact.all, OpportunityNote.all)
  end

  def initialize(person, params=nil)
    @person = person
    @params = params

    unless params.nil?
      @relationship_params = prepare_opportunity_extra_params
      params.delete_if { |k, v| [:created, :updated].include?(k)}
    end
  end

  def create_opportunity
    @opportunity = Opportunity.new(@params)
    set_default_values
    save_opportunity
  end

  def update_opportunity(opportunity_id)
    @opportunity = Opportunity.find(opportunity_id)

    if @opportunity
      @opportunity.update_attributes(@params)

      save_opportunity
    else
      {is_saved: false, errors: {errors: "there's no opportunity with that id"}}
    end
  end

  def destroy_opportunity(opportunity_id)
    opportunity = Opportunity.find(opportunity_id)

    if opportunity
      opportunity.destroy
      nil
    else
      {error: "there's no opportunity with that id"}
    end
  end

  private

  def save_opportunity
    set_opportunity_relations unless @relationship_params.nil?

    if @opportunity.save
      {is_saved: true, object: @opportunity}
    else
      {is_saved: false, errors: {errors: @opportunity.errors}}
    end
  end

  def prepare_opportunity_extra_params
    {
      contact: @params.delete(:contact),
      company: @params.delete(:company),
      owner: @params.delete(:owner),
      office: @params.delete(:office)
    }
  end

  def set_opportunity_relations
    get_contact unless @relationship_params[:contact].nil?
    get_company unless @relationship_params[:company].nil?
    get_owner unless @relationship_params[:owner].nil?
    set_office unless @relationship_params[:office].nil?
    set_contact_company
  end

  def set_default_values
    @opportunity.title = @opportunity.title || "#{@person.name}'s new opportunity"
    @opportunity.confidence = @opportunity.confidence || 'warm'
    @opportunity.stage = @opportunity.stage || 'idea'
    @opportunity.status = nil
    @opportunity.person = @person
    @opportunity.office = @person.office
  end

  def get_contact
    @opportunity.contact = Contact.find(@relationship_params[:contact])
  end

  def get_company
    @opportunity.company = Company.find(@relationship_params[:company])
  end

  def set_contact_company
    contact = @opportunity.contact
    company = @opportunity.company

    unless contact.nil?
      if !company.nil? and contact.company.nil?
        contact.company = company
        contact.save
      elsif !contact.company.nil? and company.nil?
        @opportunity.company = contact.company
      end
    end
  end

  def get_owner
    person = Person.find(@relationship_params[:owner])
    @opportunity.person = person unless person.nil?
  end

  def set_office
    office = Office.find(@relationship_params[:office])
    @opportunity.office = office unless office.nil?
  end
end
