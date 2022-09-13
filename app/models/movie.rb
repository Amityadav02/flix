class Movie < ApplicationRecord
  before_save :set_slug

  has_many :reviews, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :fans, through: :favorites, source: :user
  has_many :characterizations, dependent: :destroy
  has_many :genres, through: :characterizations
  has_one_attached :main_image

  validates :title, :released_on, :duration, presence: true

  validates :description, length: { minimum: 25 }

  validates :total_gross, numericality: { greater_than_or_equal_to: 0 }

  # validates :image_file_name, format: {
  #   with: /\w+\.(jpg|png)\z/i,
  #   message: "must be a JPG or PNG image"
  # }
  validate :acceptable_image

  RATINGS = %w(G PG PG-13 R NC-17)

  validates :rating, inclusion: { in: RATINGS }

  validates :title, presence: true, uniqueness: true

  # def self.released
  #   where("released_on < ?", Time.now).order("released_on desc")
  # end
  scope :released, -> { where("released_on < ?", Time.now).order("released_on desc") }

  scope :upcoming, -> { where("released_on > ?", Time.now).order("released_on asc") }

  scope :recent, ->(max=5) { released.limit(max) }
  
  def flop?
    total_gross.blank? || total_gross < 225_000_000
  end

  scope :hits, -> { released.where("total_gross >= 300000000").order(total_gross: :desc) }

  scope :flops, -> { released.where("total_gross < 22500000").order(total_gross: :asc) }

  def average_stars
    reviews.average(:stars) || 0.0
  end

  def set_slug
    self.slug = title.parameterize
  end

  def to_param
    slug
  end

  def acceptable_image
    return unless main_image.attached?
  
    unless main_image.blob.byte_size <= 1.megabyte
      errors.add(:main_image, "is too big")
    end
  
    acceptable_types = ["image/jpeg", "image/png"]
    unless acceptable_types.include?(main_image.content_type)
      errors.add(:main_image, "must be a JPEG or PNG")
    end
  end


end
