class ProjectValidations
  include Errapi::Model

  errapi :model do
    validates :name, presence: true, length: { maximum: 50 }
    validates :description, length: { maximum: 1000 }
  end
end