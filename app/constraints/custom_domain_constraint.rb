# Matches requests on a series' custom domain (e.g. clinelympics.com), whose
# root is that series' page instead of the platform homepage.
class CustomDomainConstraint
  def self.matches?(request)
    Series.for_host(request.host).present?
  end
end
