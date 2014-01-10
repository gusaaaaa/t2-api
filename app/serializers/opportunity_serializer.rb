class OpportunitySerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :stage, :confidence, :amount, :expected_date_close, :owner, :company, :contact, :opportunity_notes
  embed :ids, include: true

  def expected_date_close
    Time::DATE_FORMATS[:day_month_year] = '%d-%m-%Y'
    return nil if object.expected_date_close.nil?
    object.expected_date_close.to_s(:day_month_year)
  end

  def owner
    object.person.id
  end
end


#   def company
#     unless object.company.nil?
#       {
#         id: object.company.id,
#         name: object.company.name
#       }
#     end
#   end
# 
#   def contact
#     unless object.contact.nil?
#       {
#         id: object.contact.id,
#         name: object.contact.name,
#         email: object.contact.email,
#         phone: object.contact.phone
#       }
#     end
#   end
# end
