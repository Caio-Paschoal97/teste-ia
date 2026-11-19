-- Baseline for a NEW database. Never apply PostgreSQL history here.
CREATE TABLE `DailyActive` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `day` DATETIME(3) NOT NULL,
    UNIQUE INDEX `DailyActive_userId_day_key` (`userId`, `day`),
    INDEX `DailyActive_day_idx` (`day`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `FunnelEvent` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `FunnelEvent_userId_type_key` (`userId`, `type`),
    INDEX `FunnelEvent_type_createdAt_idx` (`type`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `User` (
    `id` VARCHAR(191) NOT NULL,
    `email` VARCHAR(320) NOT NULL,
    `emailVerified` BOOLEAN NOT NULL DEFAULT false,
    `name` LONGTEXT NULL,
    `username` VARCHAR(191) NOT NULL,
    `displayUsername` LONGTEXT NULL,
    `image` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `saveData` LONGTEXT NULL,
    `saveVersion` INTEGER NOT NULL DEFAULT 0,
    `saveUpdatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `saveAdoptSeq` INTEGER NOT NULL DEFAULT 0,
    `accountLevel` INTEGER NOT NULL DEFAULT 0,
    `totalCaughtLevels` INTEGER NOT NULL DEFAULT 0,
    `pokedexCaughtCount` INTEGER NOT NULL DEFAULT 0,
    `lastSeenAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `usernameChangedAt` DATETIME(3) NULL,
    `nameChangedAt` DATETIME(3) NULL,
    `dailyStreak` INTEGER NOT NULL DEFAULT 0,
    `longestDailyStreak` INTEGER NOT NULL DEFAULT 0,
    `lastDailyClaimAt` DATETIME(3) NULL,
    `awayClaimedAt` DATETIME(3) NULL,
    `isAdmin` BOOLEAN NOT NULL DEFAULT false,
    `bannedUntil` DATETIME(3) NULL,
    `banReason` LONGTEXT NULL,
    UNIQUE INDEX `User_email_key` (`email`),
    UNIQUE INDEX `User_username_key` (`username`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `StreamKey` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `key` VARCHAR(191) NOT NULL,
    `enabled` BOOLEAN NOT NULL DEFAULT true,
    `label` LONGTEXT NULL,
    `config` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `lastUsedAt` DATETIME(3) NULL,
    `lastUsedIp` LONGTEXT NULL,
    UNIQUE INDEX `StreamKey_userId_key` (`userId`),
    UNIQUE INDEX `StreamKey_key_key` (`key`),
    INDEX `StreamKey_key_idx` (`key`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `BroadcastState` (
    `id` VARCHAR(191) NOT NULL DEFAULT 'singleton',
    `enabled` BOOLEAN NOT NULL DEFAULT false,
    `accountUserId` VARCHAR(191) NULL,
    `width` INTEGER NOT NULL DEFAULT 1920,
    `height` INTEGER NOT NULL DEFAULT 1080,
    `fps` INTEGER NOT NULL DEFAULT 30,
    `bitrateKbps` INTEGER NOT NULL DEFAULT 6000,
    `updatedAt` DATETIME(3) NOT NULL,
    `live` BOOLEAN NOT NULL DEFAULT false,
    `lastStatus` LONGTEXT NULL,
    `lastStatusAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `SaveSnapshot` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `saveVersion` INTEGER NOT NULL,
    `saveData` LONGTEXT NOT NULL,
    `reason` VARCHAR(191) NOT NULL DEFAULT 'auto',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `SaveSnapshot_userId_createdAt_idx` (`userId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PendingGrant` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `prizes` LONGTEXT NOT NULL,
    `source` VARCHAR(191) NOT NULL,
    `sourceId` VARCHAR(191) NULL,
    `summary` LONGTEXT NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `deliveredAt` DATETIME(3) NULL,
    `deliveredSaveVersion` INTEGER NULL,
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `lastError` LONGTEXT NULL,
    INDEX `PendingGrant_userId_deliveredAt_idx` (`userId`, `deliveredAt`),
    INDEX `PendingGrant_deliveredAt_createdAt_idx` (`deliveredAt`, `createdAt`),
    INDEX `PendingGrant_source_sourceId_idx` (`source`, `sourceId`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Session` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `token` VARCHAR(191) NOT NULL,
    `ipAddress` LONGTEXT NULL,
    `userAgent` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    UNIQUE INDEX `Session_token_key` (`token`),
    INDEX `Session_userId_idx` (`userId`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Account` (
    `id` VARCHAR(191) NOT NULL,
    `accountId` VARCHAR(512) NOT NULL,
    `providerId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `accessToken` LONGTEXT NULL,
    `refreshToken` LONGTEXT NULL,
    `idToken` LONGTEXT NULL,
    `accessTokenExpiresAt` DATETIME(3) NULL,
    `refreshTokenExpiresAt` DATETIME(3) NULL,
    `scope` LONGTEXT NULL,
    `password` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    UNIQUE INDEX `Account_providerId_accountId_key` (`providerId`, `accountId`),
    INDEX `Account_userId_idx` (`userId`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Verification` (
    `id` VARCHAR(191) NOT NULL,
    `identifier` VARCHAR(512) NOT NULL,
    `value` LONGTEXT NOT NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    INDEX `Verification_identifier_idx` (`identifier`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Friend` (
    `id` VARCHAR(191) NOT NULL,
    `requesterId` VARCHAR(191) NOT NULL,
    `receiverId` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    UNIQUE INDEX `Friend_requesterId_receiverId_key` (`requesterId`, `receiverId`),
    INDEX `Friend_receiverId_status_idx` (`receiverId`, `status`),
    INDEX `Friend_requesterId_status_idx` (`requesterId`, `status`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `MapPosition` (
    `locationId` VARCHAR(191) NOT NULL,
    `x` DOUBLE NOT NULL,
    `y` DOUBLE NOT NULL,
    `updatedAt` DATETIME(3) NOT NULL,
    `updatedBy` VARCHAR(191) NULL,
    PRIMARY KEY (`locationId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `MapCrop` (
    `regionId` VARCHAR(191) NOT NULL,
    `x` DOUBLE NOT NULL,
    `y` DOUBLE NOT NULL,
    `w` DOUBLE NOT NULL,
    `h` DOUBLE NOT NULL,
    `updatedAt` DATETIME(3) NOT NULL,
    `updatedBy` VARCHAR(191) NULL,
    PRIMARY KEY (`regionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `BugReport` (
    `id` VARCHAR(191) NOT NULL,
    `reporterId` VARCHAR(191) NULL,
    `reporterName` LONGTEXT NOT NULL,
    `title` LONGTEXT NOT NULL,
    `description` LONGTEXT NOT NULL,
    `page` LONGTEXT NULL,
    `userAgent` LONGTEXT NULL,
    `context` LONGTEXT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'open',
    `adminNotes` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    INDEX `BugReport_status_createdAt_idx` (`status`, `createdAt`),
    INDEX `BugReport_reporterId_idx` (`reporterId`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `ErrorLog` (
    `id` VARCHAR(191) NOT NULL,
    `kind` VARCHAR(191) NOT NULL,
    `level` VARCHAR(191) NOT NULL DEFAULT 'error',
    `message` LONGTEXT NOT NULL,
    `stack` LONGTEXT NULL,
    `source` LONGTEXT NULL,
    `userId` VARCHAR(191) NULL,
    `username` VARCHAR(191) NULL,
    `userAgent` LONGTEXT NULL,
    `meta` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `ErrorLog_kind_createdAt_idx` (`kind`, `createdAt`),
    INDEX `ErrorLog_userId_createdAt_idx` (`userId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `AdminAudit` (
    `id` VARCHAR(191) NOT NULL,
    `adminId` VARCHAR(191) NOT NULL,
    `action` LONGTEXT NOT NULL,
    `targetId` VARCHAR(191) NULL,
    `meta` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `AdminAudit_adminId_createdAt_idx` (`adminId`, `createdAt`),
    INDEX `AdminAudit_targetId_createdAt_idx` (`targetId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `ChatMessage` (
    `id` VARCHAR(191) NOT NULL,
    `channelId` VARCHAR(512) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `content` LONGTEXT NOT NULL,
    `kind` VARCHAR(191) NOT NULL DEFAULT 'user',
    `meta` LONGTEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `ChatMessage_channelId_createdAt_idx` (`channelId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PvpMatch` (
    `id` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `finishedAt` DATETIME(3) NULL,
    `format` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `userAId` VARCHAR(191) NOT NULL,
    `userAUsername` LONGTEXT NOT NULL,
    `userATeam` LONGTEXT NOT NULL,
    `userBId` VARCHAR(191) NOT NULL,
    `userBUsername` LONGTEXT NOT NULL,
    `userBTeam` LONGTEXT NOT NULL,
    `winnerId` VARCHAR(191) NULL,
    `loserId` VARCHAR(191) NULL,
    `endReason` VARCHAR(191) NULL,
    `battleLog` LONGTEXT NULL,
    `tournamentId` VARCHAR(191) NULL,
    INDEX `PvpMatch_userAId_createdAt_idx` (`userAId`, `createdAt`),
    INDEX `PvpMatch_userBId_createdAt_idx` (`userBId`, `createdAt`),
    INDEX `PvpMatch_tournamentId_idx` (`tournamentId`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Giveaway` (
    `id` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `startsAt` DATETIME(3) NULL,
    `endsAt` DATETIME(3) NULL,
    `drawnAt` DATETIME(3) NULL,
    `title` LONGTEXT NOT NULL,
    `description` LONGTEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'draft',
    `winnerCount` INTEGER NOT NULL DEFAULT 1,
    `prizes` LONGTEXT NOT NULL,
    `minAccountLevel` INTEGER NULL,
    `drawSeed` LONGTEXT NULL,
    `ownerId` VARCHAR(191) NOT NULL,
    INDEX `Giveaway_status_createdAt_idx` (`status`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `GiveawayEntry` (
    `id` VARCHAR(191) NOT NULL,
    `giveawayId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `username` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `isWinner` BOOLEAN NOT NULL DEFAULT false,
    `claimedAt` DATETIME(3) NULL,
    UNIQUE INDEX `GiveawayEntry_giveawayId_userId_key` (`giveawayId`, `userId`),
    INDEX `GiveawayEntry_giveawayId_isWinner_idx` (`giveawayId`, `isWinner`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Poll` (
    `id` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `closedAt` DATETIME(3) NULL,
    `question` LONGTEXT NOT NULL,
    `options` LONGTEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'draft',
    `ownerId` VARCHAR(191) NOT NULL,
    INDEX `Poll_status_createdAt_idx` (`status`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PollVote` (
    `id` VARCHAR(191) NOT NULL,
    `pollId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `username` VARCHAR(191) NOT NULL,
    `optionIndex` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    UNIQUE INDEX `PollVote_pollId_userId_key` (`pollId`, `userId`),
    INDEX `PollVote_pollId_optionIndex_idx` (`pollId`, `optionIndex`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Announcement` (
    `id` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `type` VARCHAR(191) NOT NULL DEFAULT 'info',
    `message` LONGTEXT NOT NULL,
    `href` LONGTEXT NULL,
    `linkLabel` LONGTEXT NULL,
    `active` BOOLEAN NOT NULL DEFAULT true,
    `startsAt` DATETIME(3) NULL,
    `expiresAt` DATETIME(3) NULL,
    `createdBy` VARCHAR(191) NOT NULL,
    INDEX `Announcement_active_createdAt_idx` (`active`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Tournament` (
    `id` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `startsAt` DATETIME(3) NULL,
    `finishedAt` DATETIME(3) NULL,
    `name` LONGTEXT NOT NULL,
    `format` VARCHAR(191) NOT NULL,
    `levelCap` INTEGER NULL,
    `status` VARCHAR(191) NOT NULL,
    `bracket` LONGTEXT NULL,
    `ownerId` VARCHAR(191) NOT NULL,
    `roundWindowMinutes` INTEGER NOT NULL DEFAULT 1440,
    `autoRun` BOOLEAN NOT NULL DEFAULT true,
    `championId` VARCHAR(191) NULL,
    `championUsername` LONGTEXT NULL,
    `prizes` LONGTEXT NULL,
    `prizeGrantedAt` DATETIME(3) NULL,
    INDEX `Tournament_status_createdAt_idx` (`status`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `TournamentEntry` (
    `id` VARCHAR(191) NOT NULL,
    `tournamentId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `username` VARCHAR(191) NOT NULL,
    `seed` INTEGER NULL,
    `ratingAtSeed` INTEGER NULL,
    `eliminated` BOOLEAN NOT NULL DEFAULT false,
    `joinedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `TournamentEntry_tournamentId_userId_key` (`tournamentId`, `userId`),
    INDEX `TournamentEntry_tournamentId_eliminated_idx` (`tournamentId`, `eliminated`),
    INDEX `TournamentEntry_userId_idx` (`userId`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PlayerRating` (
    `userId` VARCHAR(191) NOT NULL,
    `rating` INTEGER NOT NULL DEFAULT 1000,
    `peakRating` INTEGER NOT NULL DEFAULT 1000,
    `matchesPlayed` INTEGER NOT NULL DEFAULT 0,
    `wins` INTEGER NOT NULL DEFAULT 0,
    `losses` INTEGER NOT NULL DEFAULT 0,
    `forfeits` INTEGER NOT NULL DEFAULT 0,
    `lastMatchAt` DATETIME(3) NULL,
    `updatedAt` DATETIME(3) NOT NULL,
    INDEX `PlayerRating_rating_idx` (`rating`),
    PRIMARY KEY (`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `TradeRecord` (
    `id` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `userAId` VARCHAR(191) NOT NULL,
    `userAUsername` LONGTEXT NOT NULL,
    `userASentMon` LONGTEXT NOT NULL,
    `userASentSpecies` LONGTEXT NOT NULL,
    `userASentLevel` INTEGER NOT NULL,
    `userBId` VARCHAR(191) NOT NULL,
    `userBUsername` LONGTEXT NOT NULL,
    `userBSentMon` LONGTEXT NOT NULL,
    `userBSentSpecies` LONGTEXT NOT NULL,
    `userBSentLevel` INTEGER NOT NULL,
    INDEX `TradeRecord_userAId_createdAt_idx` (`userAId`, `createdAt`),
    INDEX `TradeRecord_userBId_createdAt_idx` (`userBId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Auction` (
    `id` VARCHAR(191) NOT NULL,
    `sellerId` VARCHAR(191) NOT NULL,
    `pokemonId` VARCHAR(191) NOT NULL,
    `pokemonSnapshot` LONGTEXT NOT NULL,
    `startingBid` INTEGER NOT NULL,
    `currentBid` INTEGER NOT NULL DEFAULT 0,
    `currentBidderId` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'active',
    `endsAt` DATETIME(3) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `settledAt` DATETIME(3) NULL,
    INDEX `Auction_status_endsAt_idx` (`status`, `endsAt`),
    INDEX `Auction_sellerId_createdAt_idx` (`sellerId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `Bid` (
    `id` VARCHAR(191) NOT NULL,
    `auctionId` VARCHAR(191) NOT NULL,
    `bidderId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `Bid_auctionId_createdAt_idx` (`auctionId`, `createdAt`),
    INDEX `Bid_bidderId_createdAt_idx` (`bidderId`, `createdAt`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `AuctionProxyBid` (
    `auctionId` VARCHAR(191) NOT NULL,
    `bidderId` VARCHAR(191) NOT NULL,
    `maxAmount` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    INDEX `AuctionProxyBid_bidderId_idx` (`bidderId`),
    CONSTRAINT `AuctionProxyBid_positive` CHECK (`maxAmount` > 0),
    PRIMARY KEY (`auctionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PvpLadderEarn` (
    `id` VARCHAR(191) NOT NULL,
    `matchId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `opponentUserId` VARCHAR(191) NOT NULL,
    `day` DATE NOT NULL,
    `provenance` VARCHAR(191) NOT NULL,
    `result` VARCHAR(191) NOT NULL,
    `endReason` VARCHAR(191) NOT NULL,
    `turns` INTEGER NOT NULL,
    `durationMs` INTEGER NOT NULL,
    `ratingBefore` INTEGER NOT NULL,
    `ratingAfter` INTEGER NOT NULL,
    `ratingDelta` INTEGER NOT NULL,
    `meetingIndex` INTEGER NOT NULL,
    `bpBeforeDecay` INTEGER NOT NULL,
    `tier` VARCHAR(191) NOT NULL,
    `bp` INTEGER NOT NULL DEFAULT 0,
    `milestoneBp` INTEGER NOT NULL DEFAULT 0,
    `moneyAwarded` INTEGER NOT NULL DEFAULT 0,
    `winBonusPaid` BOOLEAN NOT NULL DEFAULT false,
    `grantId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `PvpLadderEarn_matchId_userId_key` (`matchId`, `userId`),
    INDEX `PvpLadderEarn_userId_createdAt_idx` (`userId`, `createdAt`),
    INDEX `PvpLadderEarn_userId_opponentUserId_createdAt_idx` (`userId`, `opponentUserId`, `createdAt`),
    INDEX `PvpLadderEarn_day_idx` (`day`),
    CONSTRAINT `PvpLadderEarn_nonneg` CHECK (`bp` >= 0 AND `milestoneBp` >= 0 AND `moneyAwarded` >= 0),
    CONSTRAINT `PvpLadderEarn_money_needs_bonus` CHECK (`moneyAwarded` = 0 OR `winBonusPaid`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PvpWinBonusClaim` (
    `userId` VARCHAR(191) NOT NULL,
    `claimedAt` DATETIME(3) NOT NULL,
    `day` DATE NOT NULL,
    `matchId` VARCHAR(191) NOT NULL,
    `rating` INTEGER NOT NULL,
    `tier` VARCHAR(191) NOT NULL,
    `money` INTEGER NOT NULL,
    INDEX `PvpWinBonusClaim_claimedAt_idx` (`claimedAt`),
    CONSTRAINT `PvpWinBonusClaim_nonneg` CHECK (`money` >= 0),
    PRIMARY KEY (`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PvpBadgeMilestone` (
    `userId` VARCHAR(191) NOT NULL,
    `threshold` INTEGER NOT NULL,
    `ratingBefore` INTEGER NOT NULL,
    `ratingAtAward` INTEGER NOT NULL,
    `bp` INTEGER NOT NULL,
    `grantId` VARCHAR(191) NULL,
    `awardedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    CONSTRAINT `PvpBadgeMilestone_nonneg` CHECK (`bp` >= 0),
    CONSTRAINT `PvpBadgeMilestone_crossed` CHECK (`ratingBefore` < `threshold`),
    PRIMARY KEY (`userId`, `threshold`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE `PvpLadderBaseline` (
    `userId` VARCHAR(191) NOT NULL,
    `rating` INTEGER NOT NULL,
    `source` VARCHAR(191) NOT NULL DEFAULT 'settle',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

ALTER TABLE `DailyActive` ADD CONSTRAINT `DailyActive_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `FunnelEvent` ADD CONSTRAINT `FunnelEvent_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `StreamKey` ADD CONSTRAINT `StreamKey_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `SaveSnapshot` ADD CONSTRAINT `SaveSnapshot_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PendingGrant` ADD CONSTRAINT `PendingGrant_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Session` ADD CONSTRAINT `Session_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Account` ADD CONSTRAINT `Account_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Friend` ADD CONSTRAINT `Friend_requesterId_fkey` FOREIGN KEY (`requesterId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Friend` ADD CONSTRAINT `Friend_receiverId_fkey` FOREIGN KEY (`receiverId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `ChatMessage` ADD CONSTRAINT `ChatMessage_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `GiveawayEntry` ADD CONSTRAINT `GiveawayEntry_giveawayId_fkey` FOREIGN KEY (`giveawayId`) REFERENCES `Giveaway`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `GiveawayEntry` ADD CONSTRAINT `GiveawayEntry_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PollVote` ADD CONSTRAINT `PollVote_pollId_fkey` FOREIGN KEY (`pollId`) REFERENCES `Poll`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PollVote` ADD CONSTRAINT `PollVote_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `TournamentEntry` ADD CONSTRAINT `TournamentEntry_tournamentId_fkey` FOREIGN KEY (`tournamentId`) REFERENCES `Tournament`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Auction` ADD CONSTRAINT `Auction_sellerId_fkey` FOREIGN KEY (`sellerId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Bid` ADD CONSTRAINT `Bid_auctionId_fkey` FOREIGN KEY (`auctionId`) REFERENCES `Auction`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `Bid` ADD CONSTRAINT `Bid_bidderId_fkey` FOREIGN KEY (`bidderId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `AuctionProxyBid` ADD CONSTRAINT `AuctionProxyBid_auctionId_fkey` FOREIGN KEY (`auctionId`) REFERENCES `Auction`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `AuctionProxyBid` ADD CONSTRAINT `AuctionProxyBid_bidderId_fkey` FOREIGN KEY (`bidderId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PvpLadderEarn` ADD CONSTRAINT `PvpLadderEarn_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PvpLadderEarn` ADD CONSTRAINT `PvpLadderEarn_opponentUserId_fkey` FOREIGN KEY (`opponentUserId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PvpWinBonusClaim` ADD CONSTRAINT `PvpWinBonusClaim_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PvpBadgeMilestone` ADD CONSTRAINT `PvpBadgeMilestone_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `PvpLadderBaseline` ADD CONSTRAINT `PvpLadderBaseline_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- MySQL forbids a CHECK on columns with cascading FK actions.
CREATE TRIGGER PvpLadderEarn_not_self_insert BEFORE INSERT ON PvpLadderEarn
FOR EACH ROW IF NEW.userId = NEW.opponentUserId THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PvpLadderEarn_not_self';
END IF;

CREATE TRIGGER PvpLadderEarn_not_self_update BEFORE UPDATE ON PvpLadderEarn
FOR EACH ROW IF NEW.userId = NEW.opponentUserId THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PvpLadderEarn_not_self';
END IF;
