# Firebase Cloud Functions Setup Guide

## 📋 What This Does
This setup moves your Gemini API key from the Flutter app to a secure Firebase server, making it safe to publish your app.

---

## 🚀 Step-by-Step Setup

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Firebase (in your project root)
```bash
cd d:\Downloads\mobcom\verity_ai
firebase init functions
```

When prompted:
- **Select a Firebase project**: Choose your existing project
- **Language**: Select **JavaScript** (not TypeScript)
- **ESLint**: No (or Yes, your choice)
- **Install dependencies**: Yes

**Note:** The init command will create a `functions/` folder. We've already created the files, so you can choose to overwrite or merge.

### 4. Install Dependencies in Functions Folder
```bash
cd functions
npm install
```

### 5. Set Your Gemini API Key (Securely)
```bash
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY_HERE"
```

Replace `YOUR_GEMINI_API_KEY_HERE` with your actual Gemini API key from https://makersuite.google.com/app/apikey

### 6. Deploy the Cloud Function
```bash
firebase deploy --only functions
```

This uploads your function to Firebase servers. Takes 2-3 minutes.

### 7. Update Flutter Dependencies
```bash
cd ..
flutter pub get
```

### 8. Test Your App
Run your Flutter app - it now calls the secure Cloud Function instead of directly calling Gemini!

---

## ✅ Verification

After deployment, you should see:
```
✔  functions[factCheckUrl(us-central1)] Deployed
```

Test in your app:
1. Enter a URL
2. Click "Analyze Link"
3. The Cloud Function handles everything securely!

---

## 💰 Costs

- **Firebase Cloud Functions**: Free tier includes 2M invocations/month
- **Gemini API**: Free tier includes 60 requests/minute
- **Perfect for your project!**

---

## 🔧 Troubleshooting

### Error: "Gemini API key not configured"
```bash
firebase functions:config:set gemini.key="YOUR_KEY"
firebase deploy --only functions
```

### Error: "Function not found"
Make sure you deployed: `firebase deploy --only functions`

### Check Function Logs
```bash
firebase functions:log
```

### Test Locally (Optional)
```bash
cd functions
npm run serve
```
Then configure your Flutter app to use the local emulator.

---

## 🔒 Security Benefits

✅ API key never in your app code  
✅ API key never in APK/IPA files  
✅ Safe to publish on Google Play/App Store  
✅ Safe to push to public GitHub  
✅ You control who can use the function (authenticated users only)  
✅ Monitor all usage in Firebase Console  

---

## 📝 Important Notes

1. **Keep your old code**: I've commented out the old `GeminiService` - you can delete it later
2. **Firebase pricing**: Stay within free tier by monitoring usage in Firebase Console
3. **Function region**: Default is `us-central1`, change in `index.js` if needed
4. **Update anytime**: Just edit `functions/index.js` and run `firebase deploy --only functions`

---

## 🎯 Quick Commands Reference

```bash
# Deploy functions
firebase deploy --only functions

# View logs
firebase functions:log

# Set config
firebase functions:config:set key="value"

# View config
firebase functions:config:get

# Delete a function
firebase functions:delete factCheckUrl
```

---

## Next Steps

1. Run through the setup steps above
2. Test your app thoroughly
3. Delete the old `gemini_service.dart` if everything works
4. You're ready to publish! 🎉
