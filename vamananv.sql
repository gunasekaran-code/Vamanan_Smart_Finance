-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: makkal_gold
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `activity_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `action` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `details` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_logs`
--

LOCK TABLES `activity_logs` WRITE;
/*!40000 ALTER TABLE `activity_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agreements`
--

DROP TABLE IF EXISTS `agreements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agreements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `agreement_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `product_id` int NOT NULL,
  `agreement_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` enum('pending','active','rejected','verified','legal_review','signed','expired') COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'Investment Deed',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `signed_at` timestamp NULL DEFAULT NULL,
  `customer_signed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `agreement_id` (`agreement_id`),
  KEY `user_id` (`user_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `agreements_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `agreements_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agreements`
--

LOCK TABLES `agreements` WRITE;
/*!40000 ALTER TABLE `agreements` DISABLE KEYS */;
INSERT INTO `agreements` VALUES (1,15,'AGR-1785131090-15',4,'2026-07-27 11:17:12','active','2026-07-27 05:44:50','Gold Acquisition Deed',NULL,NULL,NULL),(2,31,'AGR-1785743530-31',1,'2026-08-03 13:25:12','active','2026-08-03 07:52:10','Gold Acquisition Deed',NULL,NULL,NULL),(3,31,'AGR-1788158240-31',4,'2026-08-31 12:08:47','active','2026-08-31 06:37:20','Gold Acquisition Deed',NULL,NULL,NULL);
/*!40000 ALTER TABLE `agreements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cashback_applications`
--

DROP TABLE IF EXISTS `cashback_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cashback_applications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `address` text,
  `phone` varchar(20) DEFAULT NULL,
  `aadhar_no` varchar(20) DEFAULT NULL,
  `pan_no` varchar(20) DEFAULT NULL,
  `customer_code` varchar(50) DEFAULT NULL,
  `customer_email` varchar(255) DEFAULT NULL,
  `referral_id` varchar(50) DEFAULT NULL,
  `purchase_amount` decimal(15,2) DEFAULT '0.00',
  `purchased_product` varchar(255) DEFAULT NULL,
  `product_details` text,
  `purchase_date` date DEFAULT NULL,
  `bank_account_name` varchar(255) DEFAULT NULL,
  `account_no` varchar(50) DEFAULT NULL,
  `ifsc_code` varchar(20) DEFAULT NULL,
  `bank_name` varchar(255) DEFAULT NULL,
  `bank_branch` varchar(255) DEFAULT NULL,
  `agent_name` varchar(255) DEFAULT NULL,
  `agent_id` varchar(50) DEFAULT NULL,
  `place` varchar(255) DEFAULT 'Krishnagiri',
  `application_date` date DEFAULT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `cycle_id` int DEFAULT NULL,
  `gst_amount` decimal(15,2) DEFAULT '0.00',
  `total_amount` decimal(15,2) DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `cashback_applications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cashback_applications`
--

LOCK TABLES `cashback_applications` WRITE;
/*!40000 ALTER TABLE `cashback_applications` DISABLE KEYS */;
INSERT INTO `cashback_applications` VALUES (1,15,'Test User','','9632015487','','','VEV002','testuser@gmail.com','VEVA7NTF',2849000.00,'Tata Harrier Adventure+ AT','Auto-generated from order #4. Total paid ₹3,646,720.00 incl. GST ₹797,720.00. Cashback eligible ₹2,849,000.00 (GST excluded).','2026-07-27','Test User','','','','',NULL,NULL,'Krishnagiri','2026-07-27','pending','2026-07-27 05:44:50',4,797720.00,3646720.00),(2,15,'Test User','Auroville, Bommayapalayam, 605101','9632015487','9632 5874 1020','ABCDE1234F','VEV002','testuser@gmail.com','VEVA7NTF',3646720.00,'Tata Harrier Adventure+ AT','Tata Harrier Adventure+ AT','2026-07-27','Test User','9876543210231','SBIN000123','State Bank of India','Krishnagiri','','','Krishnagiri','2026-07-27','pending','2026-07-27 05:46:10',NULL,0.00,0.00),(3,31,'TestUser1','','9876543213','','','VEV003','testuser1@gmail.com','VEVHGQ44',149999.00,'Apple iPhone 16 Pro Max','Auto-generated from order #18. Total paid ₹176,998.82 incl. GST ₹26,999.82. Cashback eligible ₹149,999.00 (GST excluded).','2026-08-03','TestUser1','','','','',NULL,NULL,'Krishnagiri','2026-08-03','pending','2026-08-03 07:52:10',18,26999.82,176998.82),(4,31,'TestUser1','artsrdytjkllsrsdjd','9876543213','1234 5669 8765','GHIJK9876L','VEV003','testuser1@gmail.com','VEVHGQ44',176998.82,'Apple iPhone 16 Pro Max','Apple iPhone 16 Pro Max','2026-08-03','TestUser1','121000105256','UBIN0001234','Union Bank of India','Main','','','Krishnagiri','2026-08-03','pending','2026-08-03 07:54:05',NULL,0.00,0.00),(5,31,'TestUser1','','9876543213','','','VEV003','testuser1@gmail.com','VEVHGQ44',2849000.00,'Tata Harrier Adventure+ AT','Auto-generated from order #22. Total paid ₹3,646,720.00 incl. GST ₹797,720.00. Cashback eligible ₹2,849,000.00 (GST excluded).','2026-08-31','TestUser1','','','','',NULL,NULL,'Krishnagiri','2026-08-31','pending','2026-08-31 06:37:20',22,797720.00,3646720.00),(6,31,'TestUser1','dsfdfxhn yghjhgkj','9876543213','7945 9638 5241','HGFJJ4523F','VEV003','testuser1@gmail.com','VEVHGQ44',3646720.00,'Tata Harrier Adventure+ AT','Tata Harrier Adventure+ AT','2026-08-31','TestUser1','8529637418852963','DFGH744105','sdfghgjdfg','hdjhdghdfgdfh','','','Krishnagiri','2026-08-31','pending','2026-08-31 06:38:20',NULL,0.00,0.00);
/*!40000 ALTER TABLE `cashback_applications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cashback_cycles`
--

DROP TABLE IF EXISTS `cashback_cycles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cashback_cycles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `asset_type` enum('gold','silver','product') COLLATE utf8mb4_general_ci DEFAULT 'gold',
  `weight` decimal(10,3) DEFAULT '0.000',
  `product_id` int DEFAULT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `product_amount` decimal(15,2) DEFAULT '0.00',
  `gst_amount` decimal(15,2) DEFAULT '0.00',
  `total_amount` decimal(15,2) DEFAULT '0.00',
  `cashback_eligible_amount` decimal(15,2) DEFAULT '0.00',
  `total_value` decimal(15,2) NOT NULL,
  `daily_payout` decimal(15,2) NOT NULL,
  `paid_amount` decimal(15,2) DEFAULT '0.00',
  `transaction_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `payment_screenshot` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `days_paid` int DEFAULT '0',
  `status` enum('active','completed','paused','pending','rejected','cancelled') COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `referral_paid` tinyint(1) NOT NULL DEFAULT '0',
  `last_paid_at` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `payment_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'Bank Transfer',
  `ledger_txn_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `cashback_cycles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cashback_cycles`
--

LOCK TABLES `cashback_cycles` WRITE;
/*!40000 ALTER TABLE `cashback_cycles` DISABLE KEYS */;
INSERT INTO `cashback_cycles` VALUES (4,15,'product',1.000,4,'Tata Harrier Adventure+ AT',2849000.00,797720.00,3646720.00,2849000.00,3646720.00,284900.00,629779.98,'638492017451','uploads/payments/pay_1785131090_15.jpeg',2,'active',0,'2026-08-03','2026-07-27 05:44:50','Bank Transfer',6),(18,31,'product',1.000,1,'Apple iPhone 16 Pro Max',149999.00,26999.82,176998.82,149999.00,176998.82,14999.90,14999.90,'986532014795','uploads/payments/pay_1785743530_31.png',1,'active',0,'2026-08-03','2026-08-03 07:52:10','Bank Transfer',30),(22,31,'product',1.000,4,'Tata Harrier Adventure+ AT',2849000.00,797720.00,3646720.00,2849000.00,3646720.00,284900.00,0.00,'96385274185','uploads/payments/pay_1788158240_31.png',0,'active',1,NULL,'2026-08-31 06:37:20','Bank Transfer',36);
/*!40000 ALTER TABLE `cashback_cycles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=309327 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES (7,'Electronics','electronics','2026-05-28 05:03:43'),(9,'Gold','gold','2026-06-01 10:49:26'),(10,'House Construction','house-construction','2026-06-01 10:49:27'),(11,'All Construction Material','all-construction-material','2026-06-01 10:49:27'),(13,'Vehicles (2wheeler/4wheeler)','vehicles-2wheeler-4wheeler','2026-06-01 10:49:27'),(14,'Groceries','groceries','2026-06-01 10:49:27');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compliance_audit`
--

DROP TABLE IF EXISTS `compliance_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compliance_audit` (
  `id` int NOT NULL AUTO_INCREMENT,
  `admin_id` int NOT NULL,
  `target_user_id` int DEFAULT NULL,
  `audit_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `details` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compliance_audit`
--

LOCK TABLES `compliance_audit` WRITE;
/*!40000 ALTER TABLE `compliance_audit` DISABLE KEYS */;
/*!40000 ALTER TABLE `compliance_audit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `disputes`
--

DROP TABLE IF EXISTS `disputes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `disputes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `dispute_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `priority` enum('low','medium','high','urgent') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'medium',
  `status` enum('open','in_resolution','resolved','closed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dispute_id` (`dispute_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `disputes`
--

LOCK TABLES `disputes` WRITE;
/*!40000 ALTER TABLE `disputes` DISABLE KEYS */;
/*!40000 ALTER TABLE `disputes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `export_history`
--

DROP TABLE IF EXISTS `export_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `export_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `filename` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `export_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `total_amount` decimal(15,2) DEFAULT NULL,
  `total_records` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `export_history`
--

LOCK TABLES `export_history` WRITE;
/*!40000 ALTER TABLE `export_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `export_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedbacks`
--

DROP TABLE IF EXISTS `feedbacks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedbacks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `from_user_id` int NOT NULL,
  `to_user_id` int DEFAULT NULL,
  `from_role` varchar(20) DEFAULT 'customer',
  `direction` enum('customer_to_admin','admin_to_customer') DEFAULT 'customer_to_admin',
  `subject` varchar(255) DEFAULT NULL,
  `message` text NOT NULL,
  `rating` tinyint DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedbacks`
--

LOCK TABLES `feedbacks` WRITE;
/*!40000 ALTER TABLE `feedbacks` DISABLE KEYS */;
/*!40000 ALTER TABLE `feedbacks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `holidays`
--

DROP TABLE IF EXISTS `holidays`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `holidays` (
  `id` int NOT NULL AUTO_INCREMENT,
  `holiday_date` date NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(30) DEFAULT 'government',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `holiday_date` (`holiday_date`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `holidays`
--

LOCK TABLES `holidays` WRITE;
/*!40000 ALTER TABLE `holidays` DISABLE KEYS */;
INSERT INTO `holidays` VALUES (3,'2026-08-15','Independance Day','government','2026-08-03 06:20:50');
/*!40000 ALTER TABLE `holidays` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_alerts`
--

DROP TABLE IF EXISTS `inventory_alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_alerts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `alert_type` enum('low_stock','out_of_stock','overstock') DEFAULT 'low_stock',
  `current_qty` int DEFAULT '0',
  `threshold` int DEFAULT '10',
  `is_resolved` tinyint(1) DEFAULT '0',
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `inventory_alerts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_alerts`
--

LOCK TABLES `inventory_alerts` WRITE;
/*!40000 ALTER TABLE `inventory_alerts` DISABLE KEYS */;
/*!40000 ALTER TABLE `inventory_alerts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `invoice_no` varchar(30) DEFAULT NULL,
  `cycle_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `customer_code` varchar(50) DEFAULT NULL,
  `customer_phone` varchar(30) DEFAULT NULL,
  `customer_email` varchar(255) DEFAULT NULL,
  `asset_type` varchar(20) DEFAULT NULL,
  `product_name` varchar(500) DEFAULT NULL,
  `items_json` text,
  `taxable_amount` decimal(15,2) DEFAULT '0.00',
  `gst_rate` decimal(6,2) DEFAULT '0.00',
  `cgst_amount` decimal(15,2) DEFAULT '0.00',
  `sgst_amount` decimal(15,2) DEFAULT '0.00',
  `gst_amount` decimal(15,2) DEFAULT '0.00',
  `total_amount` decimal(15,2) DEFAULT '0.00',
  `payment_method` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(255) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'issued',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `invoice_no` (`invoice_no`),
  KEY `idx_invoices_cycle` (`cycle_id`),
  KEY `idx_invoices_user` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoices`
--

LOCK TABLES `invoices` WRITE;
/*!40000 ALTER TABLE `invoices` DISABLE KEYS */;
INSERT INTO `invoices` VALUES (1,'INV-000001',4,15,'Test User','VEV002','9632015487','testuser@gmail.com','product','Tata Harrier Adventure+ AT','[{\"name\":\"Tata Harrier Adventure+ AT\",\"qty\":1,\"rate\":2849000,\"base\":2849000,\"gstRate\":28}]',2849000.00,28.00,398860.00,398860.00,797720.00,3646720.00,'Bank Transfer','638492017451','issued','2026-07-27 05:44:50'),(2,'INV-000002',18,31,'TestUser1','VEV003','9876543213','testuser1@gmail.com','product','Apple iPhone 16 Pro Max','[{\"name\":\"Apple iPhone 16 Pro Max\",\"qty\":1,\"rate\":149999,\"base\":149999,\"gstRate\":18}]',149999.00,18.00,13499.91,13499.91,26999.82,176998.82,'Bank Transfer','986532014795','issued','2026-08-03 07:52:10'),(3,'INV-000003',22,31,'TestUser1','VEV003','9876543213','testuser1@gmail.com','product','Tata Harrier Adventure+ AT','[{\"name\":\"Tata Harrier Adventure+ AT\",\"qty\":1,\"rate\":2849000,\"base\":2849000,\"gstRate\":28}]',2849000.00,28.00,398860.00,398860.00,797720.00,3646720.00,'Bank Transfer','96385274185','issued','2026-08-31 06:37:20');
/*!40000 ALTER TABLE `invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login_otps`
--

DROP TABLE IF EXISTS `login_otps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_otps` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `otp_hash` varchar(255) NOT NULL,
  `attempts` int DEFAULT '0',
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_otps`
--

LOCK TABLES `login_otps` WRITE;
/*!40000 ALTER TABLE `login_otps` DISABLE KEYS */;
/*!40000 ALTER TABLE `login_otps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `type` enum('info','warning','success','payout') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,15,'Order Submitted','Your order for \'Tata Harrier Adventure+ AT\' (₹3,646,720.00) has been submitted and is pending admin approval. Product delivered within 7 working days; payout starts within 48 hours of approval.','success',1,'2026-07-27 05:44:50'),(2,15,'Investment Approved','Your investment has been approved! Daily rewards are now active and will be credited every day.','success',1,'2026-07-27 05:47:12'),(3,31,'Order Submitted','Your order for \'Apple iPhone 16 Pro Max\' (₹176,998.82) has been submitted and is pending admin approval. Product delivered within 7 working days; payout starts within 48 hours of approval.','success',0,'2026-08-03 07:52:10'),(4,31,'Investment Approved','Your investment has been approved! Daily rewards are now active and will be credited every day.','success',0,'2026-08-03 07:55:12'),(7,31,'Order Submitted','Your order for \'Tata Harrier Adventure+ AT\' (₹3,646,720.00) has been submitted and is pending admin approval. Product delivered within 7 working days; payout starts within 48 hours of approval.','success',0,'2026-08-31 06:37:20'),(8,31,'Investment Approved','Your investment has been approved! Daily rewards are now active and will be credited every day.','success',0,'2026-08-31 06:38:47');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `offers`
--

DROP TABLE IF EXISTS `offers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `message` text,
  `image` varchar(255) DEFAULT NULL,
  `badge` varchar(50) DEFAULT 'OFFER',
  `color` varchar(20) DEFAULT 'blue',
  `is_active` tinyint(1) DEFAULT '1',
  `starts_at` datetime DEFAULT NULL,
  `ends_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `offers`
--

LOCK TABLES `offers` WRITE;
/*!40000 ALTER TABLE `offers` DISABLE KEYS */;
/*!40000 ALTER TABLE `offers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `otp_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `attempts` int DEFAULT '0',
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `platform_settings`
--

DROP TABLE IF EXISTS `platform_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `platform_settings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `config_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `config_value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_key` (`config_key`)
) ENGINE=InnoDB AUTO_INCREMENT=355460 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `platform_settings`
--

LOCK TABLES `platform_settings` WRITE;
/*!40000 ALTER TABLE `platform_settings` DISABLE KEYS */;
INSERT INTO `platform_settings` VALUES (1,'referral_commission_l1','2','2026-07-27 05:05:39'),(2,'referral_commission_l2','0.1','2026-05-14 07:47:55'),(3,'referral_commission_l3','0.1','2026-05-14 07:47:56'),(4,'referral_commission_l4','0.05','2026-05-14 07:47:56'),(5,'referral_commission_l5','0.05','2026-05-14 07:47:56'),(6,'min_withdrawal','2000','2026-08-03 06:00:49'),(7,'gold_base_price','14735.54','2026-08-07 08:07:31'),(8,'silver_base_price','300','2026-07-09 11:35:08'),(9,'gst_percentage','3','2026-05-14 07:47:56'),(10,'maintenance_mode','0','2026-05-14 07:47:56'),(11,'payout_processing_fee','10','2026-07-13 14:41:49'),(12,'daily_cashback_rate','2','2026-07-27 05:05:39'),(13,'min_investment','1000','2026-05-14 07:47:56'),(14,'support_phone','+91 90000 00000','2026-05-14 07:47:56'),(15,'support_email','support@makkalgold.com','2026-05-14 07:47:56'),(16,'company_name','Vamanan Enterprises V','2026-07-13 14:40:53'),(17,'company_address','123, Gold Plaza, Main Road, City, State, 600001','2026-05-14 07:47:56'),(18,'upi_id','vamanan@upi','2026-05-14 07:47:56'),(55234,'bank_name','Canara Bank','2026-05-22 05:20:12'),(55235,'bank_account_name','Vamanan Enterprises V Pvt Ltd','2026-05-22 05:20:12'),(55236,'bank_account_no','638492017451','2026-05-22 05:20:12'),(55237,'bank_ifsc','CNRB0002987','2026-05-22 05:20:12'),(55238,'bank_branch','T Nagar Branch, Chennai','2026-05-22 05:20:12'),(77127,'gold_gst','3','2026-06-17 04:37:11'),(77128,'general_gst','10','2026-07-13 14:41:44'),(154738,'last_yield_run','2026-08-31','2026-08-31 06:03:53'),(210066,'marketing_investor_offset','5000','2026-07-11 06:10:42'),(210067,'marketing_capital_offset','500000000','2026-07-11 06:10:42'),(210068,'marketing_payout_offset','1000000','2026-07-11 06:10:42'),(210637,'tds_charges_rate','10','2026-07-13 14:14:41'),(215523,'tds_rate','5','2026-07-13 14:43:45'),(215524,'service_charge_rate','5','2026-07-13 14:43:45'),(228889,'referral_commission_rate','2','2026-07-27 05:05:39'),(236703,'cashback_skip_weekends','1','2026-07-27 10:29:28'),(238355,'plan_duration_months','10','2026-07-28 05:23:23'),(240108,'manual_yield_run_month','2026-08','2026-08-03 07:56:32');
/*!40000 ALTER TABLE `platform_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_requests`
--

DROP TABLE IF EXISTS `product_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `customer_code` varchar(50) DEFAULT NULL,
  `customer_email` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `model` varchar(255) DEFAULT NULL,
  `category` varchar(100) DEFAULT 'Gold',
  `quantity` int DEFAULT '1',
  `weight` decimal(10,3) DEFAULT '0.000',
  `expected_price` decimal(15,2) DEFAULT '0.00',
  `description` text,
  `status` enum('pending','reviewing','approved','rejected','fulfilled') DEFAULT 'pending',
  `admin_note` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `product_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_requests`
--

LOCK TABLES `product_requests` WRITE;
/*!40000 ALTER TABLE `product_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_code` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'Gold Asset',
  `slug` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `is_active` tinyint(1) DEFAULT '1',
  `price` decimal(15,2) NOT NULL,
  `gst_rate` decimal(5,2) DEFAULT NULL,
  `image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `weight` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '1 Gram',
  `purity` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '24K',
  `stock` int DEFAULT '0',
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `stock_quantity` int NOT NULL DEFAULT '0',
  `low_stock_threshold` int NOT NULL DEFAULT '10',
  `stock_notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  UNIQUE KEY `product_code` (`product_code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,'VEVP001','Apple iPhone 16 Pro Max','Electronics','apple-iphone-16-pro-max-1785129934','Premium flagship smartphone featuring a powerful processor, advanced AI capabilities, professional-grade camera system, Super Retina XDR display, long-lasting battery, and ultra-fast 5G connectivity. Ideal for business professionals, content creators, and everyday users seeking premium performance and reliability.',1,149999.00,18.00,'api/uploads/products/1785129934_6a66ebce25612.png','0','256GB • Titanium Black • 12GB RAM',0,NULL,'2026-07-27 05:25:34','2026-07-27 05:38:27',25,10,NULL),(3,'VEVP002','Samsung Galaxy S25 Ultra','Electronics','samsung-galaxy-s25-ultra-1785130832','Samsung Galaxy S25 Ultra delivers flagship performance with an advanced AI processor, professional quad-camera setup, Dynamic AMOLED display, S-Pen support, and all-day battery life for productivity and entertainment.',1,134999.00,18.00,'api/uploads/products/1785130832_6a66ef509a1cc.png','0','512GB • 12GB RAM',0,NULL,'2026-07-27 05:40:32','2026-07-27 05:40:32',18,10,NULL),(4,'VEVP003','Tata Harrier Adventure+ AT','Vehicles (2wheeler/4wheeler)','tata-harrier-adventure-at-1785131002','Premium SUV featuring a 2.0L turbo diesel engine, 6-speed automatic transmission, panoramic sunroof, 360° camera, ADAS safety features, premium leather interior, connected car technology, and advanced infotainment system. Ideal for personal and commercial use with superior comfort, performance, and safety.',1,2849000.00,28.00,'api/uploads/products/1785131002_6a66effaba441.png','0','2.0L Kryotec Diesel • 6-Speed Automatic • 5-Seater',0,NULL,'2026-07-27 05:43:22','2026-07-27 05:43:22',8,10,NULL);
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `settings_audit`
--

DROP TABLE IF EXISTS `settings_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings_audit` (
  `id` int NOT NULL AUTO_INCREMENT,
  `config_key` varchar(100) NOT NULL,
  `old_value` text,
  `new_value` text,
  `changed_by` varchar(255) DEFAULT 'admin',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_settings_audit_key` (`config_key`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settings_audit`
--

LOCK TABLES `settings_audit` WRITE;
/*!40000 ALTER TABLE `settings_audit` DISABLE KEYS */;
INSERT INTO `settings_audit` VALUES (1,'plan_duration_months','10','11','admin-test','2026-07-28 05:23:22'),(2,'plan_duration_months','11','10','admin-test','2026-07-28 05:23:23'),(3,'gold_base_price','14064.81','20000','admin','2026-08-03 06:00:01'),(4,'min_withdrawal','1000','2000','admin','2026-08-03 06:00:49'),(5,'manual_yield_run_month','2026-08','2026-07','admin','2026-08-03 06:05:02'),(6,'last_yield_run','2026-08-03','2026-07-01','admin','2026-08-03 06:05:02');
/*!40000 ALTER TABLE `settings_audit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stock_movements`
--

DROP TABLE IF EXISTS `stock_movements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_movements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `movement_type` enum('add','remove','adjust','sale','return','initial') DEFAULT 'adjust',
  `quantity` int NOT NULL DEFAULT '0',
  `previous_qty` int NOT NULL DEFAULT '0',
  `new_qty` int NOT NULL DEFAULT '0',
  `notes` text,
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `stock_movements_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stock_movements`
--

LOCK TABLES `stock_movements` WRITE;
/*!40000 ALTER TABLE `stock_movements` DISABLE KEYS */;
/*!40000 ALTER TABLE `stock_movements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `support_tickets`
--

DROP TABLE IF EXISTS `support_tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `support_tickets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `priority` enum('Low','Medium','High') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'Medium',
  `status` enum('open','resolved','closed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `support_tickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `support_tickets`
--

LOCK TABLES `support_tickets` WRITE;
/*!40000 ALTER TABLE `support_tickets` DISABLE KEYS */;
/*!40000 ALTER TABLE `support_tickets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tally_audit_log`
--

DROP TABLE IF EXISTS `tally_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tally_audit_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `action` varchar(80) NOT NULL,
  `entity` varchar(80) NOT NULL,
  `entity_id` varchar(64) DEFAULT NULL,
  `detail` text,
  `amount` decimal(15,2) DEFAULT NULL,
  `actor` varchar(128) DEFAULT 'system',
  `ip` varchar(64) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tally_audit_log`
--

LOCK TABLES `tally_audit_log` WRITE;
/*!40000 ALTER TABLE `tally_audit_log` DISABLE KEYS */;
INSERT INTO `tally_audit_log` VALUES (1,'export','ledger','inventory','Exported Inventory Ledger as xml (0 rows)',NULL,'admin','::1','2026-07-27 04:36:38');
/*!40000 ALTER TABLE `tally_audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tally_settings`
--

DROP TABLE IF EXISTS `tally_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tally_settings` (
  `skey` varchar(64) NOT NULL,
  `svalue` text,
  PRIMARY KEY (`skey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tally_settings`
--

LOCK TABLES `tally_settings` WRITE;
/*!40000 ALTER TABLE `tally_settings` DISABLE KEYS */;
INSERT INTO `tally_settings` VALUES ('company','');
/*!40000 ALTER TABLE `tally_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tally_sync_log`
--

DROP TABLE IF EXISTS `tally_sync_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tally_sync_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `resource` varchar(64) NOT NULL,
  `gateway` varchar(255) DEFAULT NULL,
  `records` int DEFAULT '0',
  `created` int DEFAULT NULL,
  `altered` int DEFAULT NULL,
  `errors` int DEFAULT NULL,
  `amount` decimal(15,2) DEFAULT '0.00',
  `status` enum('success','partial','error') DEFAULT 'success',
  `message` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tally_sync_log`
--

LOCK TABLES `tally_sync_log` WRITE;
/*!40000 ALTER TABLE `tally_sync_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tally_sync_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tally_vouchers`
--

DROP TABLE IF EXISTS `tally_vouchers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tally_vouchers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `voucher_no` varchar(64) NOT NULL,
  `voucher_type` enum('Sales','Purchase','Receipt','Payment','Journal','Contra','Credit Note','Debit Note') DEFAULT 'Journal',
  `voucher_date` date NOT NULL,
  `party_ledger` varchar(255) DEFAULT NULL,
  `debit_ledger` varchar(255) DEFAULT NULL,
  `credit_ledger` varchar(255) DEFAULT NULL,
  `amount` decimal(15,2) DEFAULT '0.00',
  `narration` text,
  `reference` varchar(128) DEFAULT NULL,
  `source` enum('manual','sales','customer','cashback','referral','withdrawal','inventory') DEFAULT 'manual',
  `source_id` int DEFAULT NULL,
  `sync_status` enum('draft','posted','synced','error') DEFAULT 'draft',
  `tally_guid` varchar(128) DEFAULT NULL,
  `created_by` varchar(128) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tally_vouchers`
--

LOCK TABLES `tally_vouchers` WRITE;
/*!40000 ALTER TABLE `tally_vouchers` DISABLE KEYS */;
/*!40000 ALTER TABLE `tally_vouchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `wallet_id` int NOT NULL,
  `type` enum('credit','debit') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum('purchase','purchase_request','referral','cashback','payout','withdrawal','liquidation','manual','deposit','other') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'other',
  `amount` decimal(15,2) NOT NULL,
  `gross_amount` decimal(15,2) DEFAULT NULL,
  `tds_amount` decimal(15,2) DEFAULT NULL,
  `charges_amount` decimal(15,2) DEFAULT NULL,
  `deduction` decimal(15,2) DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `status` enum('pending','completed','failed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'completed',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `wallet_id` (`wallet_id`),
  CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES (6,16,'debit','purchase_request',3646720.00,NULL,NULL,NULL,NULL,'Investment Request: Tata Harrier Adventure+ AT (Approved)','completed','2026-07-27 05:44:50'),(28,16,'credit','cashback',256410.00,284900.00,14245.00,14245.00,28490.00,'MANUAL: Daily Cashback Payout (net of TDS + charges)','completed','2026-07-28 05:03:05'),(29,16,'credit','cashback',256410.00,284900.00,14245.00,14245.00,28490.00,'Monthly 10% cashback on ₹2,849,000.00 (excl. GST) — Month 2 of 10 — gross ₹284,900.00 less TDS 5% ₹14,245.00 + charges 5% ₹14,245.00 = net ₹256,410.00 — Cycle #4','completed','2026-08-03 04:45:51'),(30,32,'debit','purchase_request',176998.82,NULL,NULL,NULL,NULL,'Investment Request: Apple iPhone 16 Pro Max (Approved)','completed','2026-08-03 07:52:10'),(31,16,'credit','referral',2999.98,NULL,NULL,NULL,NULL,'Referral Commission from TestUser1 (2.0% flat)','completed','2026-08-03 07:55:12'),(32,32,'credit','cashback',13499.90,14999.90,750.00,750.00,1500.00,'Monthly 10% cashback on ₹149,999.00 (excl. GST) — Month 1 of 10 — gross ₹14,999.90 less TDS 5% ₹750.00 + charges 5% ₹750.00 = net ₹13,499.90 — Cycle #18','completed','2026-08-03 07:56:32'),(33,16,'credit','referral',2699.98,2999.98,150.00,150.00,300.00,'Referral Commission (2%) from User #31 — gross ₹2,999.98 less TDS 5% ₹150.00 + charges 5% ₹150.00 = net ₹2,699.98','completed','2026-08-03 07:56:32'),(36,32,'debit','purchase_request',3646720.00,NULL,NULL,NULL,NULL,'Investment Request: Tata Harrier Adventure+ AT (Approved)','completed','2026-08-31 06:37:20'),(37,16,'credit','referral',51282.00,56980.00,2849.00,2849.00,5698.00,'Referral Commission (2%) from TestUser1 (User #31) — gross ₹56,980.00 less TDS 5% ₹2,849.00 + charges 5% ₹2,849.00 = net ₹51,282.00 — Cycle #22','completed','2026-08-31 06:38:47');
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `role` enum('admin','manager','staff','advocate','auditor','customer') COLLATE utf8mb4_general_ci DEFAULT 'customer',
  `status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'active',
  `referral_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `referral_active` tinyint(1) NOT NULL DEFAULT '1',
  `referrer_id` int DEFAULT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `address` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `aadhar_no` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pan_no` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `kyc_document` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `bank_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `account_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `ifsc_code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `kyc_status` enum('pending','verified','rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notify_email` tinyint(1) DEFAULT '1',
  `notify_system` tinyint(1) DEFAULT '1',
  `branch_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `permissions` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `referral_code` (`referral_code`),
  UNIQUE KEY `customer_id` (`customer_id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'VEV001','Vamanan Enterprises V','admin@makkalgold.com','password','admin','active','VEVWKB4S',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'','2026-05-13 12:19:55',1,1,NULL,NULL),(15,'VEV002','Test User','testuser@gmail.com','123456','customer','active','VEVA7NTF',1,NULL,'9632015487',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pending','2026-07-27 05:26:36',1,1,NULL,NULL),(29,'VEV-AUD','Auditor','auditor@makkalgold.com','auditor@123','auditor','active','VEV13QWA',1,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pending','2026-07-28 05:15:02',1,1,NULL,NULL),(31,'VEV003','TestUser1','testuser1@gmail.com','123456','customer','active','VEVHGQ44',1,15,'9876543213',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pending','2026-08-03 07:51:01',1,1,NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wallets`
--

DROP TABLE IF EXISTS `wallets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `balance` decimal(15,2) DEFAULT '0.00',
  `total_earned` decimal(15,2) DEFAULT '0.00',
  `total_withdrawn` decimal(15,2) DEFAULT '0.00',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `wallets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallets`
--

LOCK TABLES `wallets` WRITE;
/*!40000 ALTER TABLE `wallets` DISABLE KEYS */;
INSERT INTO `wallets` VALUES (9,1,0.00,0.00,0.00,'2026-07-13 16:11:47'),(16,15,569801.96,569801.96,0.00,'2026-08-31 06:38:47'),(32,31,13499.90,13499.90,0.00,'2026-08-03 07:56:32');
/*!40000 ALTER TABLE `wallets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `withdrawals`
--

DROP TABLE IF EXISTS `withdrawals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `withdrawals` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `bank_details` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `status` enum('pending','approved','rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `payment_method` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `transaction_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `processed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `withdrawals_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `withdrawals`
--

LOCK TABLES `withdrawals` WRITE;
/*!40000 ALTER TABLE `withdrawals` DISABLE KEYS */;
/*!40000 ALTER TABLE `withdrawals` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-11 11:13:10
