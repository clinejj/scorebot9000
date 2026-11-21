class User < ApplicationRecord
  has_prefixed_id :usr

  has_many :sessions, dependent: :delete_all
  has_many :participants, dependent: :destroy
  has_many :events, through: :participants
  has_many :memberships, dependent: :delete_all
  has_many :host_requests, dependent: :destroy
  has_many :sms_messages, dependent: :nullify
  belongs_to :sms_context_event, class_name: "Event", optional: true

  # Deterministic encryption keeps these queryable and uniquely indexable
  # while storing ciphertext (which is also what Blazer shows).
  encrypts :email, deterministic: true
  encrypts :pending_email, deterministic: true
  encrypts :phone, deterministic: true

  normalizes :email, :pending_email, with: ->(email) { email.strip.downcase.presence }
  normalizes :phone, with: ->(phone) { PhoneNumber.normalize(phone) }

  validates :email, uniqueness: true, allow_nil: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :pending_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :phone, uniqueness: true, allow_nil: true
  validates :name, length: { maximum: 80 }
  validate :has_contact_method

  scope :platform_admins, -> { where(platform_admin: true) }

  # Signs in by a verified email: an existing account, or one an organizer
  # mapped to this email (pending_email), or a new account.
  def self.from_verified_email!(email)
    transaction do
      user = find_by(email: email) || find_by(pending_email: email) || new
      user.email = email
      user.pending_email = nil if user.pending_email == user.email
      user.email_verified_at ||= Time.current
      user.save!
      user
    end
  end

  def flipper_id
    public_id
  end

  def display_name
    name.presence || email&.split("@")&.first || PhoneNumber.mask(phone) || "Player"
  end

  def grant_platform_admin!
    update!(platform_admin: true)
  end

  def revoke_platform_admin!
    update!(platform_admin: false)
  end

  private
    def has_contact_method
      errors.add(:base, "needs an email or phone number") if email.blank? && phone.blank? && pending_email.blank?
    end
end
