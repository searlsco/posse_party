class Platforms::Bsky
  class OpensSession
    def open(account)
      Bskyrb::Session.new(
        Bskyrb::Credentials.new(account.credentials["email"], account.credentials["password"]),
        PDS_URL
      )
    end
  end
end
