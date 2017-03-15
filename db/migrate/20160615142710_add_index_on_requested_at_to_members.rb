class AddIndexOnRequestedAtToMembers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :members, :requested_at
  end
end
