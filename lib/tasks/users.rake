namespace :users do
  # Bootstraps the first platform admin. The admin UI (and the
  # Users::GrantPlatformAdminTask there) is itself behind the admin gate, so
  # the first grant has to come from a shell:
  #
  #   fly ssh console -a scorebot9000 -C "bin/rails users:grant_admin EMAIL=you@example.com"
  desc "Grant platform admin to EMAIL (creating the user if needed)"
  task grant_admin: :environment do
    email = ENV.fetch("EMAIL") { abort "Usage: bin/rails users:grant_admin EMAIL=you@example.com" }
    user = User.find_by(email: email) || User.create!(email: email)
    user.grant_platform_admin!
    AdminAuditEvent.record!("users.grant_admin", subject: user.public_id, user: nil, via: "rake")
    puts "#{user.public_id} (#{user.email}) is now a platform admin. Sign in at /session/new with that email."
  end

  desc "Revoke platform admin from EMAIL"
  task revoke_admin: :environment do
    email = ENV.fetch("EMAIL") { abort "Usage: bin/rails users:revoke_admin EMAIL=you@example.com" }
    user = User.find_by!(email: email)
    user.revoke_platform_admin!
    AdminAuditEvent.record!("users.revoke_admin", subject: user.public_id, user: nil, via: "rake")
    puts "#{user.public_id} is no longer a platform admin."
  end
end
