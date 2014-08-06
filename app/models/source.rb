# == Schema Information
#
# Table name: sources
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  region_id        :integer
#  document_type_id :integer
#  pdf              :string(255)
#  processed        :boolean          default(TRUE)
#

class Source < ActiveRecord::Base
  attr_accessor :gregorian_date_string, :lunar_hijri_date_string

  before_save :set_processed
  before_save :prepend_http_to_source_url
  after_commit :generate_images
  alias_attribute :name, :title

  validates :title, presence: true
  validate :validate_dates

  has_and_belongs_to_many :themes
  has_and_belongs_to_many :topics
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :eras
  has_and_belongs_to_many :reference_types
  has_many :pages, dependent: :destroy
  belongs_to :region
  belongs_to :document_type
  belongs_to :language

  mount_uploader :pdf, PdfUploader
  accepts_nested_attributes_for :pages

  private

  def generate_images
    changes = self.previous_changes
    if changes.include?(:pdf) && changes[:pdf].first != changes[:pdf].last
      PdfToImagesWorker.perform_async self.id
    end
  end

  def set_processed
    if self.pdf_changed? && !self.new_record? || self.new_record? && self.pdf
      self.processed = false
    end
    return true
  end

  def prepend_http_to_source_url
    unless self.source_url =~ /^https?:\/\//
      self.source_url = "http://#{self.source_url}"
    end
  end

  def validate_dates
    ['gregorian_date', 'lunar_hijri_date'].each do |attr|
      attr_string = attr + '_string'
      if self.public_send(attr_string).present?
        begin
          date = self.public_send(attr_string).split('-')[0..2].map(&:to_i)
          self.public_send(attr + '=', Date.new(*date).to_s)
        rescue ArgumentError
          self.errors[attr_string] << 'Invalid Date'
        end
      else
        self.public_send(attr + '=', nil)
      end
    end
  end
end