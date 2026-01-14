// Migration Script: Convert Comments from PostID to Generic EntityID/EntityType
//
// This script migrates existing comments from the legacy PostID format
// to the new generic EntityID/EntityType format.
//
// Run this script using MongoDB shell:
//   mongosh mongodb://localhost:27017/streetcore < migrate_comments_to_generic.js
//
// Or from within mongosh:
//   load('migrate_comments_to_generic.js')

print("========================================");
print("Comment Migration: PostID → EntityID/EntityType");
print("========================================\n");

// Connect to the database (adjust connection if needed)
const db = db.getSiblingDB('streetcore');

print("Step 1: Checking comments collection...");
const totalComments = db.comments.countDocuments({});
print(`Total comments in database: ${totalComments}\n`);

// Step 2: Find comments with legacy PostID but without EntityID
print("Step 2: Finding comments with legacy PostID...");
const legacyComments = db.comments.countDocuments({
  postId: { $exists: true },
  entityId: { $exists: false }
});
print(`Comments with legacy PostID: ${legacyComments}\n`);

if (legacyComments === 0) {
  print("✅ No comments need migration. All comments already use EntityID/EntityType.\n");
  print("Migration complete!");
  quit(0);
}

// Step 3: Migrate comments
print("Step 3: Migrating comments to new format...");
print("This will:");
print("  - Copy 'postId' → 'entityId'");
print("  - Set 'entityType' = 'post'");
print("  - Keep 'postId' for backward compatibility\n");

try {
  const result = db.comments.updateMany(
    {
      postId: { $exists: true },
      entityId: { $exists: false }
    },
    [
      {
        $set: {
          entityId: "$postId",
          entityType: "post"
        }
      }
    ]
  );

  print(`✅ Migration successful!`);
  print(`   - Matched: ${result.matchedCount} documents`);
  print(`   - Modified: ${result.modifiedCount} documents\n`);

  // Step 4: Verify migration
  print("Step 4: Verifying migration...");
  const remainingLegacy = db.comments.countDocuments({
    postId: { $exists: true },
    entityId: { $exists: false }
  });

  if (remainingLegacy === 0) {
    print("✅ Verification passed! All comments migrated successfully.\n");
  } else {
    print(`⚠️  Warning: ${remainingLegacy} comments still need migration.\n`);
  }

  // Step 5: Show sample migrated comment
  print("Step 5: Sample migrated comment:");
  const sample = db.comments.findOne({ entityId: { $exists: true } });
  if (sample) {
    print(JSON.stringify({
      id: sample._id,
      entityId: sample.entityId,
      entityType: sample.entityType,
      postId: sample.postId || "(not set)",
      text: sample.text.substring(0, 50) + "...",
      userId: sample.userId
    }, null, 2));
  }
  print("");

  // Step 6: Create indexes for new fields
  print("Step 6: Creating indexes for entityId and entityType...");

  // Drop old index if exists
  try {
    db.comments.dropIndex("postId_1");
    print("  - Dropped old 'postId' index");
  } catch (e) {
    print("  - No old 'postId' index to drop (or already dropped)");
  }

  // Create new compound index
  db.comments.createIndex(
    { entityType: 1, entityId: 1, createdAt: -1 },
    { name: "entityType_entityId_createdAt" }
  );
  print("  - Created new compound index: entityType_entityId_createdAt");

  // Create index for user comments
  db.comments.createIndex(
    { userId: 1, createdAt: -1 },
    { name: "userId_createdAt" }
  );
  print("  - Created index: userId_createdAt\n");

  print("========================================");
  print("✅ Migration completed successfully!");
  print("========================================");
  print("\nSummary:");
  print(`  - Total comments: ${totalComments}`);
  print(`  - Migrated: ${result.modifiedCount}`);
  print(`  - Remaining legacy: ${remainingLegacy}`);
  print("\nNext steps:");
  print("  1. Test the comment system with the new API");
  print("  2. Monitor for any issues");
  print("  3. After confirming stability, you can optionally remove 'postId' field");
  print("     (keep it for now to maintain backward compatibility)\n");

} catch (error) {
  print("❌ Migration failed!");
  print(`Error: ${error.message}\n`);
  print("No changes were made. Please check the error and try again.");
  quit(1);
}
