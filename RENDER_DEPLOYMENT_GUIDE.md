# Render.com Deployment Guide for Modular System

## 🚨 Critical Issues Fixed

### 1. **Environment Variables Configuration**
Your Gcash payment integration was failing because these environment variables were not configured in Render.com:

**Required Environment Variables:**
```
PAYMONGO_SECRET_KEY=sk_test_your_paymongo_secret_key_here
PAYMONGO_SUCCESS_URL=https://your-app-name.onrender.com/payment/success
PAYMONGO_CANCEL_URL=https://your-app-name.onrender.com/payment/cancel
APP_URL=https://your-app-name.onrender.com
```

### 2. **Dockerfile Issues**
- Using `artisan serve` (development mode) instead of production web server
- Missing proper web server configuration
- No environment variable handling

## 📋 Step-by-Step Deployment Instructions

### Step 1: Update Your Render.com Service

1. **Go to your Render.com dashboard**
2. **Select your service**
3. **Go to Environment tab**
4. **Add these environment variables:**

```bash
# Application
APP_NAME=Modular System
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-app-name.onrender.com

# Database (if using Render's managed PostgreSQL)
DB_CONNECTION=pgsql
DB_HOST=your-render-postgres-host
DB_PORT=5432
DB_DATABASE=your-database-name
DB_USERNAME=your-database-user
DB_PASSWORD=your-database-password

# PayMongo Configuration (CRITICAL FOR GCASH PAYMENTS)
PAYMONGO_SECRET_KEY=sk_test_your_paymongo_secret_key_here
PAYMONGO_SUCCESS_URL=https://your-app-name.onrender.com/payment/success
PAYMONGO_CANCEL_URL=https://your-app-name.onrender.com/payment/cancel

# Mail Configuration
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME=Modular System

# Cache
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
FILESYSTEM_DISK=local
```

### Step 2: Update Your Dockerfile

Replace your current `Dockerfile` with the production version:

```bash
# Rename current Dockerfile
mv Dockerfile Dockerfile.old

# Use the production Dockerfile
mv Dockerfile.production Dockerfile
```

### Step 3: Generate Application Key

Before deploying, generate your application key:

```bash
# In your local project directory
php artisan key:generate --show
```

Copy the generated key and add it to Render.com environment variables as:
```
APP_KEY=base64:your_generated_key_here
```

### Step 4: Configure PayMongo

1. **Get your PayMongo credentials:**
   - Go to [PayMongo Dashboard](https://dashboard.paymongo.com/)
   - Get your Secret Key from the API Keys section
   - Update `PAYMONGO_SECRET_KEY` in Render.com

2. **Update URLs:**
   - Replace `your-app-name` with your actual Render.com app name
   - Ensure URLs use HTTPS (required by PayMongo)

### Step 5: Deploy

1. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Fix Gcash payment integration for Render.com deployment"
   git push origin main
   ```

2. **Render.com will automatically redeploy**

### Step 6: Test Payment Integration

1. **Check logs in Render.com dashboard**
2. **Test payment flow:**
   - Go to payment page
   - Try to make a payment
   - Check if PayMongo checkout loads
   - Verify success/cancel URLs work

## 🔧 Troubleshooting

### If payments still don't work:

1. **Check Render.com logs:**
   - Go to your service dashboard
   - Click on "Logs" tab
   - Look for PayMongo-related errors

2. **Verify environment variables:**
   - Ensure all PayMongo variables are set
   - Check that URLs are correct and use HTTPS

3. **Test PayMongo API directly:**
   ```bash
   curl -X POST https://api.paymongo.com/v1/checkout_sessions \
     -H "Authorization: Bearer YOUR_SECRET_KEY" \
     -H "Content-Type: application/json" \
     -d '{"data":{"attributes":{"line_items":[{"name":"Test","quantity":1,"currency":"PHP","amount":10000}],"payment_method_types":["gcash"],"success_url":"https://your-app.onrender.com/success","cancel_url":"https://your-app.onrender.com/cancel"}}}'
   ```

## ✅ Verification Checklist

- [ ] All environment variables set in Render.com
- [ ] Dockerfile updated to production version
- [ ] APP_KEY generated and configured
- [ ] PayMongo credentials are correct
- [ ] URLs use HTTPS and correct domain
- [ ] Database connection working
- [ ] Payment flow tested end-to-end

## 🆘 Support

If you continue to have issues:
1. Check Render.com logs for specific error messages
2. Verify PayMongo dashboard for API usage
3. Test with PayMongo's test credentials first
4. Contact support with specific error messages from logs
