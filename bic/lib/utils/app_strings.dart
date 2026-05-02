class AppStrings {
  final bool isKurdish;
  const AppStrings(this.isKurdish);

  // ── Bottom Nav ──────────────────────────────────────────────
  String get navHome       => isKurdish ? 'ماڵ'        : 'Home';
  String get navSearch     => isKurdish ? 'گەڕان'      : 'Search';
  String get navCreate     => isKurdish ? 'دروستکردن'  : 'Create';
  String get navReels      => isKurdish ? 'ڕیل'        : 'Reels';
  String get navProfile    => isKurdish ? 'پرۆفایل'    : 'Profile';

  // ── Profile screen ──────────────────────────────────────────
  String get editProfile   => isKurdish ? 'دەستکاریی پرۆفایل' : 'Edit profile';
  String get shareProfile  => isKurdish ? 'هاوبەشکردنی پرۆفایل' : 'Share profile';
  String get savedPosts    => isKurdish ? 'پۆستە سەیڤکراوەکان' : 'Saved posts';
  String get posts         => isKurdish ? 'پۆست'       : 'Posts';
  String get followers     => isKurdish ? 'شوێنکەوتوو'  : 'Followers';
  String get following     => isKurdish ? 'شوێنکەوتن'   : 'Following';

  // ── Feed ────────────────────────────────────────────────────
  String get noPosts       => isKurdish ? 'هیچ پۆستێک نییە' : 'No posts yet';
  String get noReels       => isKurdish ? 'هیچ ڕیلێک نییە' : 'No reels yet';
  String get noTagged      => isKurdish ? 'هیچ تاگکراوێک نییە' : 'No tagged posts';

  // ── Saved screen ────────────────────────────────────────────
  String get savedTitle     => isKurdish ? 'پۆستە سەیڤکراوەکان' : 'Saved posts';
  String get noSaved        => isKurdish ? 'هیچ پۆستێک سەیڤ نەکراوە' : 'No saved posts yet';
  String get noSavedSub     => isKurdish ? 'پۆستەکانت سەیڤ بکە تا لێرە ببینیتەوە' : 'Save posts to see them here';
  String get unsave         => isKurdish ? 'لابردن لە سەیڤکراوەکان' : 'Remove from saved';
  String get savedAdded     => isKurdish ? 'زیادکرا بۆ سەیڤکراوەکان ✅' : 'Added to saved ✅';
  String get savedRemoved   => isKurdish ? 'لابرا لە سەیڤکراوەکان' : 'Removed from saved';

  // ── Settings screen ─────────────────────────────────────────
  String get settings       => isKurdish ? 'ڕێکخستنەکان'      : 'Settings';
  String get account        => isKurdish ? 'هەژمار'            : 'Account';
  String get accountInfo    => isKurdish ? 'زانیاریەکانی هەژمار' : 'Account info';
  String get accountInfoSub => isKurdish ? 'بینین و دەستکاریکردنی زانیاری' : 'View and edit your account info';
  String get changePassword => isKurdish ? 'گۆڕینی وشەی نهێنی' : 'Change password';
  String get changePasswordSub => isKurdish ? 'وشەی نهێنی خۆت نوێ بکەرەوە' : 'Update your password';
  String get privacySecurity => isKurdish ? 'تایبەتێتی و پاراستن' : 'Privacy & Security';
  String get privacy        => isKurdish ? 'تایبەتێتی هەژمار'   : 'Privacy';
  String get privacySub     => isKurdish ? 'ڕێکخستنەکانی تایبەتێتی' : 'Privacy settings';
  String get security       => isKurdish ? 'پاراستن'            : 'Security';
  String get securitySub    => isKurdish ? 'ڕێکخستنەکانی پاراستن و دڵنیایی' : 'Security & safety settings';
  String get notifications  => isKurdish ? 'ئاگادارکردنەوەکان'  : 'Notifications';
  String get notifSub       => isKurdish ? 'ڕێکخستنی ئاگادارکردنەوەکان' : 'Notification preferences';
  String get business       => isKurdish ? 'بزنس'             : 'Business';
  String get appearance     => isKurdish ? 'دەرکەوتن'           : 'Appearance';
  String get theme          => isKurdish ? 'ڕووکار'             : 'Theme';
  String get themeDark      => isKurdish ? 'ڕووکاری تاریک'     : 'Dark mode';
  String get themeLight     => isKurdish ? 'ڕووکاری ڕووناک'    : 'Light mode';
  String get language       => isKurdish ? 'زمان'               : 'Language';
  String get languageSub    => isKurdish ? 'کوردی / English'    : 'English / Kurdish';
  String get about          => isKurdish ? 'دەربارە'            : 'About';
  String get aboutBic       => isKurdish ? 'دەربارەی BIC'       : 'About BIC';
  String get version        => isKurdish ? 'وەشان'              : 'Version';
  String get helpSupport    => isKurdish ? 'یارمەتی و پشتگیری'  : 'Help & Support';
  String get helpSub        => isKurdish ? 'یارمەتی بگرە یان کێشەکان ڕاپۆرت بکە' : 'Get help or report issues';
  String get logout         => isKurdish ? 'دەرچوون'            : 'Log out';
  String get logoutConfirm  => isKurdish ? 'دڵنیایت لە دەرچوون؟' : 'Are you sure you want to log out?';
  String get cancel         => isKurdish ? 'پاشگەزبوونەوە'      : 'Cancel';

  // ── Create sheet ────────────────────────────────────────────
  String get whatCreate     => isKurdish ? 'چی دروست دەکەی؟'    : 'What do you want to create?';
  String get post           => isKurdish ? 'پۆست'               : 'Post';
  String get postSub        => isKurdish ? 'وێنە یان ڤیدیۆ'     : 'Photo or video';
  String get story          => isKurdish ? 'ستۆری'              : 'Story';
  String get storySub       => isKurdish ? '٢٤ کاتژمێر'         : '24 hours';
  String get reels          => isKurdish ? 'ڕیل'                : 'Reels';
  String get comingSoon     => isKurdish ? 'بەزووی'             : 'Soon';
  String get scanQrTitle    => isKurdish ? 'سکانی QR کۆد'       : 'Scan QR Code';
  String get scanQrSub      => isKurdish ? 'پرۆفایلی BIC بکە بە QR' : 'Open a BIC profile via QR';

  // ── Bottom sheet menu ───────────────────────────────────────
  String get menuSettings   => isKurdish ? 'ڕێکخستنەکان'       : 'Settings';
  String get menuActivity   => isKurdish ? 'چالاکییەکانت'       : 'Your activity';
  String get menuSaved      => isKurdish ? 'سەیڤکراوەکان'       : 'Saved';
  String get menuQR         => isKurdish ? 'QR کۆد'             : 'QR code';
  String get menuLogout     => isKurdish ? 'دەرچوون'            : 'Log out';
  String get comingSoonMsg  => isKurdish ? 'زووترین کاتدا دەسەلمێنرێت ' : 'Coming soon ';

  // ── Map ─────────────────────────────────────────────────────
  String get mapPosts       => isKurdish ? 'پۆستەکان'           : 'Posts';
  String get mapUsers       => isKurdish ? 'بەکارهێنەران'       : 'Users';
  String get mapMe          => isKurdish ? 'تۆ'                 : 'You';

  // ── Logout ───────────────────────────────────────────────────
  String get loggingOut     => isKurdish ? 'دەرچوون...'          : 'Logging out...';
  String get logoutError    => isKurdish ? 'هەڵە لە دەرچوون'     : 'Logout error';

  // ── Auth ─────────────────────────────────────────────────────
  String get login          => isKurdish ? 'چوونەژوورەوە'        : 'Log in';
  String get email          => isKurdish ? 'ئیمەیڵ'              : 'Email';
  String get password       => isKurdish ? 'وشەی نهێنی'          : 'Password';
  String get username       => isKurdish ? 'ناوی بەکارهێنەر'     : 'Username';
  String get fullName       => isKurdish ? 'ناوی تەواو'           : 'Full name';
  String get country        => isKurdish ? 'وڵات'                : 'Country';
  String get confirmPass    => isKurdish ? 'دڵنیاکردنەوەی وشەی نهێنی' : 'Confirm password';
  String get forgotPassword => isKurdish ? 'وشەی نهێنیت لەبیرکردووە؟' : 'Forgot password?';
  String get createAccount  => isKurdish ? 'دروستکردنی هەژمار'   : 'Create account';
  String get alreadyHave    => isKurdish ? 'هەژمارت هەیە؟'       : 'Already have an account?';
  String get noAccount      => isKurdish ? 'هەژمارت نییە؟'       : 'Don\'t have an account?';
  String get orContinueWith => isKurdish ? 'یان بە'               : 'Or continue with';

  // ── Feed / Posts ─────────────────────────────────────────────
  String get like           => isKurdish ? 'لایک'                : 'Like';
  String get comment        => isKurdish ? 'کۆمێنت'              : 'Comment';
  String get share          => isKurdish ? 'هاوبەشکردن'          : 'Share';
  String get save           => isKurdish ? 'سەیڤ'                : 'Save';
  String get viewAllComments => isKurdish ? 'هەموو کۆمێنتەکان ببینە' : 'View all comments';
  String get likes          => isKurdish ? 'لایک'                : 'likes';
  String get writeComment   => isKurdish ? 'کۆمێنت بنووسە...'    : 'Write a comment...';
  String get follow         => isKurdish ? 'شوێنکەوتن'            : 'Follow';
  String get unfollow       => isKurdish ? 'هەڵوەشاندنی شوێنکەوتن' : 'Unfollow';
  String get followingBtn   => isKurdish ? 'شوێنکەوتووە'          : 'Following';
  String get loadError      => isKurdish ? 'هەڵەی بارکردن'        : 'Load error';
  String get retry          => isKurdish ? 'دووبارە هەوڵ بدە'     : 'Retry';

  // ── Search ───────────────────────────────────────────────────
  String get searchHint     => isKurdish ? 'گەڕان بۆ بەکارهێنەران...' : 'Search for users...';
  String get noResults      => isKurdish ? 'هیچ ئەنجامێک نەدۆزرایەوە' : 'No results found';
  String get people         => isKurdish ? 'کەسان'               : 'People';
  String get map            => isKurdish ? 'نەخشە'               : 'Map';

  // ── Profile ──────────────────────────────────────────────────
  String get bio            => isKurdish ? 'بیۆ'                 : 'Bio';
  String get addBio         => isKurdish ? 'بیۆ زیاد بکە'        : 'Add bio';
  String get profilePhoto   => isKurdish ? 'وێنەی پرۆفایل'       : 'Profile photo';
  String get takePhoto      => isKurdish ? 'وێنە بگرە'           : 'Take photo';
  String get chooseGallery  => isKurdish ? 'هەڵبژێرە لە گەلەری'  : 'Choose from gallery';
  String get removePhoto    => isKurdish ? 'سڕینەوەی وێنە'        : 'Remove photo';
  String get saveChanges    => isKurdish ? 'پاشەکەوتکردنی گۆڕانکاری' : 'Save changes';
  String get profileFixed   => isKurdish ? 'پرۆفایلەکەت چاککرایەوە! ✅' : 'Profile fixed! ✅';
  String get failedProfile  => isKurdish ? 'بارکردنی پرۆفایل سەرکەوتوو نەبوو' : 'Failed to load profile';

  // ── Notifications ────────────────────────────────────────────
  String get noNotifications => isKurdish ? 'هیچ ئاگادارکردنەوەیەک نییە' : 'No notifications yet';
  String get likedPost      => isKurdish ? 'پۆستەکەت لایک کرد'   : 'liked your post';
  String get commentedPost  => isKurdish ? 'لە پۆستەکەت کۆمێنت کرد' : 'commented on your post';
  String get startedFollowing => isKurdish ? 'شوێنت کەوت'         : 'started following you';

  // ── Create Post ──────────────────────────────────────────────
  String get newPost        => isKurdish ? 'پۆستی نوێ'           : 'New post';
  String get addCaption     => isKurdish ? 'کاپشن زیاد بکە...'   : 'Add a caption...';
  String get selectImage    => isKurdish ? 'وێنە هەڵبژێرە'       : 'Select image';
  String get postSuccess    => isKurdish ? 'پۆست بە سەرکەوتوویی پابلیشکرا ✅' : 'Post published successfully ✅';
  String get postError      => isKurdish ? 'هەڵە لە پابلیشکردنی پۆست' : 'Error publishing post';
  String get publish        => isKurdish ? 'پابلیشکردن'           : 'Publish';

  // ── Change Password screen ───────────────────────────────────
  String get changePasswordTitle  => isKurdish ? 'گۆڕینی وشەی نهێنی'    : 'Change Password';
  String get changePasswordDesc   => isKurdish ? 'بۆ گۆڕینی وشەی نهێنی، تکایە وشەی نهێنی ئێستا و وشەی نهێنی نوێ بنووسە' : 'To change your password, enter your current and new password';
  String get currentPassword      => isKurdish ? 'وشەی نهێنی ئێستا'      : 'Current password';
  String get newPassword          => isKurdish ? 'وشەی نهێنی نوێ'         : 'New password';
  String get confirmNewPassword   => isKurdish ? 'دووپاتکردنەوەی وشەی نهێنی نوێ' : 'Confirm new password';
  String get passwordMinLength    => isKurdish ? 'لانیکەم ٦ کاراکتەر'    : 'At least 6 characters';
  String get enterCurrentPassword => isKurdish ? 'تکایە وشەی نهێنی ئێستا بنووسە' : 'Please enter current password';
  String get enterNewPassword     => isKurdish ? 'تکایە وشەی نهێنی نوێ بنووسە' : 'Please enter new password';
  String get confirmPasswordHint  => isKurdish ? 'تکایە وشەی نهێنی دووپات بکەرەوە' : 'Please confirm your password';
  String get passwordsNotMatch    => isKurdish ? 'وشەی نهێنیەکان وەک یەک نین' : 'Passwords do not match';
  String get passwordTooShort     => isKurdish ? 'وشەی نهێنی دەبێت لانیکەم ٦ کاراکتەر بێت' : 'Password must be at least 6 characters';
  String get passwordSameAsOld    => isKurdish ? 'وشەی نهێنی نوێ دەبێت جیاواز بێت لە ئێستا' : 'New password must differ from current';
  String get changeBtn            => isKurdish ? 'گۆڕین'                  : 'Change';
  String get passwordChanged      => isKurdish ? 'وشەی نهێنی بە سەرکەوتوویی گۆڕدرا' : 'Password changed successfully';
  String get wrongPassword        => isKurdish ? 'وشەی نهێنی ئێستا هەڵەیە' : 'Current password is incorrect';
  String get weakPassword         => isKurdish ? 'وشەی نهێنی نوێ زۆر لاوازە' : 'New password is too weak';
  String get reloginRequired      => isKurdish ? 'تکایە دووبارە login بکەرەوە' : 'Please log in again';
  String get errorOccurred        => isKurdish ? 'هەڵە ڕوویدا'            : 'An error occurred';

  // ── Account Info screen ──────────────────────────────────────
  String get accountInfoTitle     => isKurdish ? 'زانیاریەکانی هەژمار'   : 'Account Info';
  String get usernameLabel        => isKurdish ? 'ناوی بەکارهێنەر'        : 'Username';
  String get fullNameLabel        => isKurdish ? 'ناوی تەواو'              : 'Full Name';
  String get emailLabel           => isKurdish ? 'ئیمەیڵ'                 : 'Email';
  String get postsCountLabel      => isKurdish ? 'ژمارەی پۆستەکان'        : 'Posts Count';
  String get followersLabel       => isKurdish ? 'فۆڵۆوەرەکان'            : 'Followers';
  String get followingLabel       => isKurdish ? 'فۆڵۆو'                  : 'Following';
  String get verifiedLabel        => isKurdish ? 'دۆخی هەژمار'            : 'Account Status';
  String get bioLabel             => isKurdish ? 'دەربارەی'               : 'About';
  String get joinedLabel          => isKurdish ? 'دروستکراوە لە'          : 'Joined';
  String get unknownLabel         => isKurdish ? 'نەزانراو'               : 'Unknown';
  String get noBioLabel           => isKurdish ? 'هیچ بایۆیەک نییە'       : 'No bio yet';
  String get profileNotLoaded     => isKurdish ? 'زانیاری هەژمار بارنەبوو' : 'Could not load account info';

  // ── Privacy Settings screen ──────────────────────────────────
  String get privacyTitle         => isKurdish ? 'ڕێکخستنەکانی تایبەتێتی' : 'Privacy Settings';
  String get accountStatusSection => isKurdish ? 'دۆخی هەژمار'            : 'Account Status';
  String get privateAccountTitle  => isKurdish ? 'هەژماری تایبەت'         : 'Private Account';
  String get privateAccountSub    => isKurdish ? 'تەنها فۆڵۆوەرەکانت پۆستەکانت دەبینن' : 'Only your followers can see your posts';
  String get activitySection      => isKurdish ? 'چالاکی'                 : 'Activity';
  String get showActivityTitle    => isKurdish ? 'پیشاندانی دۆخی چالاکی' : 'Show Activity Status';
  String get showActivitySub      => isKurdish ? 'خەڵک دەزانن کاتێک ئۆنلاینیت' : 'Let others see when you\'re online';
  String get interactionSection   => isKurdish ? 'کارلێککردن'             : 'Interactions';
  String get allowCommentsTitle   => isKurdish ? 'ڕێگە بە کۆمێنتەکان'    : 'Allow Comments';
  String get allowCommentsSub     => isKurdish ? 'هەموو کەس دەتوانێت کۆمێنت بکات' : 'Anyone can comment on your posts';
  String get allowMentionsTitle   => isKurdish ? 'ڕێگە بە mention'        : 'Allow Mentions';
  String get allowMentionsSub     => isKurdish ? 'خەڵک دەتوانن mention ت بکەن' : 'Others can mention you';
  String get allowTaggingTitle    => isKurdish ? 'ڕێگە بە tagging'        : 'Allow Tagging';
  String get allowTaggingSub      => isKurdish ? 'خەڵک دەتوانن tag ت بکەن لە پۆستەکانیاندا' : 'Others can tag you in posts';
  String get privacyFutureNote    => isKurdish ? 'ئەم ڕێکخستنانە فیچەری داهاتوون و لە ڤێرژنی داهاتوودا چالاک دەکرێن' : 'These settings are upcoming features and will be activated in a future version';

  // ── Security Settings screen ─────────────────────────────────
  String get securityTitle         => isKurdish ? 'ڕێکخستنەکانی ئاسایش'           : 'Security Settings';
  String get accountSecuritySection => isKurdish ? 'دڵنیایی هەژمار'                : 'Account Security';
  String get twoFactorTitle        => isKurdish ? 'پشتڕاستکردنەوەی دوو هێنایی'     : 'Two-Factor Authentication';
  String get twoFactorSub          => isKurdish ? 'زیادکردنی لایەرێکی تری ئاسایش'  : 'Add an extra layer of security';
  String get loginAlertsTitle      => isKurdish ? 'ئاگادارکردنەوەی چوونەژوورەوە'   : 'Login Alerts';
  String get loginAlertsSub        => isKurdish ? 'ئاگادارکردنەوە بۆ چوونەژوورەوە لە ئامێرێکی نوێ' : 'Alert when signing in from a new device';
  String get dataSection           => isKurdish ? 'داتا و زانیاری'                 : 'Data & Info';
  String get saveLoginInfoTitle    => isKurdish ? 'پاراستنی زانیاری login'         : 'Save Login Info';
  String get saveLoginInfoSub      => isKurdish ? 'خۆکار login بوون لە ئامێرەکەتدا' : 'Stay logged in on this device';
  String get accessSection         => isKurdish ? 'دەسەڵات'                        : 'Access';
  String get viewDevicesTitle      => isKurdish ? 'بینینی ئامێرە login کراوەکان'   : 'Logged-in Devices';
  String get viewDevicesSub        => isKurdish ? 'بەڕێوەبردنی ئامێرە login کراوەکان' : 'Manage your active devices';
  String get securityFutureNote    => isKurdish ? 'هەندێک لەم فیچەرانە لە ڤێرژنی داهاتوودا چالاک دەکرێن' : 'Some features will be activated in a future version';
  String get twoFactorDialog       => isKurdish ? 'پشتڕاستکردنەوەی دوو هێنایی'     : 'Two-Factor Authentication';
  String get twoFactorDialogMsg    => isKurdish ? 'ئەم فیچەرە لە ڤێرژنی داهاتوودا بەردەست دەبێت' : 'This feature will be available in a future version';
  String get devicesDialog         => isKurdish ? 'ئامێرە login کراوەکان'          : 'Logged-in Devices';
  String get currentDevice         => isKurdish ? 'ئامێری ئێستا'                   : 'Current Device';
  String get currentDeviceActive   => isKurdish ? 'ئێستا چالاکە'                   : 'Currently active';

  // ── Notification Settings screen ─────────────────────────────
  String get notifSettingsTitle    => isKurdish ? 'ئاگادارکردنەوەکان'              : 'Notifications';
  String get notifActionsSection   => isKurdish ? 'ئاگادارکردنەوەی کردارەکان'      : 'Activity Notifications';
  String get notifLikesTitle       => isKurdish ? 'لایکەکان'                       : 'Likes';
  String get notifLikesSub         => isKurdish ? 'ئاگادارکردنەوە کاتێک کەسێک پۆستەکەت لایک دەکات' : 'Notify when someone likes your post';
  String get notifCommentsTitle    => isKurdish ? 'کۆمێنتەکان'                     : 'Comments';
  String get notifCommentsSub      => isKurdish ? 'ئاگادارکردنەوە بۆ کۆمێنتی نوێ' : 'Notify for new comments';
  String get notifFollowTitle      => isKurdish ? 'فۆڵۆوەرە نوێیەکان'             : 'New Followers';
  String get notifFollowSub        => isKurdish ? 'ئاگادارکردنەوە کاتێک کەسێک فۆڵۆوت دەکات' : 'Notify when someone follows you';
  String get notifMentionsTitle    => isKurdish ? 'Mentions'                       : 'Mentions';
  String get notifMentionsSub      => isKurdish ? 'ئاگادارکردنەوە کاتێک mention ت دەکەن' : 'Notify when you are mentioned';
  String get notifMessagesSection  => isKurdish ? 'نامەکان'                        : 'Messages';
  String get notifMsgTitle         => isKurdish ? 'نامەی نوێ'                      : 'New Messages';
  String get notifMsgSub           => isKurdish ? 'ئاگادارکردنەوە بۆ نامەی نوێ'   : 'Notify for new messages';
  String get notifTypeSection      => isKurdish ? 'شێوازی ئاگادارکردنەوە'          : 'Notification Type';
  String get pushNotifTitle        => isKurdish ? 'Push Notifications'             : 'Push Notifications';
  String get pushNotifSub          => isKurdish ? 'وەرگرتنی ئاگادارکردنەوە لە مۆبایل' : 'Receive notifications on mobile';
  String get emailNotifTitle       => isKurdish ? 'ئاگادارکردنەوە بە ئیمەیڵ'      : 'Email Notifications';
  String get emailNotifSub         => isKurdish ? 'وەرگرتنی ئاگادارکردنەوە بە ئیمەیڵ' : 'Receive notifications by email';
  String get notifFutureNote       => isKurdish ? 'ئەم ڕێکخستنانە لە ڤێرژنی داهاتوودا بە تەواوی کار دەکەن' : 'These settings will be fully active in a future version';

  // ── Help screen ───────────────────────────────────────────────
  String get helpTitle             => isKurdish ? 'یارمەتی'                        : 'Help';
  String get faqSection            => isKurdish ? 'پرسیارە باوەکان'                : 'FAQ';
  String get helpQ1                => isKurdish ? 'چۆن پۆست دروست بکەم؟'          : 'How do I create a post?';
  String get helpA1                => isKurdish ? 'کلیک لە دوگمەی + لە خوارەوە بکە، وێنەیەک هەڵبژێرە، caption زیاد بکە و Share بکە.' : 'Tap the + button at the bottom, pick an image, add a caption and tap Share.';
  String get helpQ2                => isKurdish ? 'چۆن فۆڵۆوی کەسێک بکەم؟'        : 'How do I follow someone?';
  String get helpA2                => isKurdish ? 'بڕۆ بۆ پرۆفایلی ئەو کەسە و کلیک لە دوگمەی "Follow" بکە.' : 'Go to that person\'s profile and tap the "Follow" button.';
  String get helpQ3                => isKurdish ? 'چۆن وشەی نهێنیم بگۆڕم؟'        : 'How do I change my password?';
  String get helpA3                => isKurdish ? 'بڕۆ بۆ Settings > Security > Change Password و هەنگاوەکان جێبەجێ بکە.' : 'Go to Settings > Security > Change Password and follow the steps.';
  String get helpQ4                => isKurdish ? 'چۆن هەژمارەکەم بسڕمەوە؟'       : 'How do I delete my account?';
  String get helpA4                => isKurdish ? 'ئەم فیچەرە لە ڤێرژنی داهاتوودا بەردەست دەبێت. لەم کاتەدا پەیوەندی بە پشتگیری بکە.' : 'This feature will be available in a future version. For now, contact support.';
  String get contactSection        => isKurdish ? 'پێویستت بە یارمەتییە؟'          : 'Need help?';
  String get contactSub            => isKurdish ? 'پەیوەندی بە تیمی پشتگیری بکە'  : 'Contact our support team';
  String get contactBtn            => isKurdish ? 'پەیوەندی پێوە بکە'             : 'Contact Us';
  String get contactDialogTitle    => isKurdish ? 'پەیوەندی بە پشتگیری'           : 'Contact Support';
  String get contactDialogMsg      => isKurdish ? 'دەتوانیت لە ڕێگەی ئەم کەناڵانەوە پەیوەندی بکەیت:' : 'You can reach us through these channels:';

  // ── Analytics Dashboard ──────────────────────────────────────
  // ── Rate App ─────────────────────────────────────────────────
  String get rateAppTitle        => isKurdish ? 'هەڵسەنگاندنی BIC'               : 'Rate BIC';
  String get rateAppSub          => isKurdish ? 'ڕایت لەسەر ئەپەکە بدە'          : 'Share your feedback about the app';
  String get rateAppStarHint     => isKurdish ? 'چەند ستێرە دەدەیت بۆ ئەپەکە؟'   : 'How many stars for BIC?';
  String get rateAppFeedbackHint => isKurdish ? 'تێبینی یان پێشنیارت هەیە؟ (دڵخوازانە)' : 'Any comments or suggestions? (optional)';
  String get rateAppSubmit       => isKurdish ? 'ناردنی ڕای'                      : 'Submit Rating';
  String get rateAppThanks       => isKurdish ? 'سوپاست، ڕایەکەت گرتمانەوە ✅'   : 'Thanks for your feedback! ✅';
  String get rateAppAlready      => isKurdish ? 'پێشتر ڕایت داوە، سوپاس!'         : 'You\'ve already rated, thanks!';
  String get rateAppPlayStore    => isKurdish ? 'هەڵسەنگاندن لە Play Store'       : 'Rate on Play Store';
  String get rateAppSection      => isKurdish ? 'هەڵسەنگاندن'                     : 'Feedback';

  // ── QR Business Card ─────────────────────────────────────────
  String get qrCardTitle         => isKurdish ? 'کارتی بیزنەسەکەم'                : 'My Business Card';
  String get qrScanTitle         => isKurdish ? 'سکانی QR کۆد'                   : 'Scan QR Code';
  String get qrScanHint          => isKurdish ? 'دوربینەکە ئاراستەی QR کۆد بکە'  : 'Point camera at a BIC QR code';
  String get qrScanSuccess       => isKurdish ? 'پرۆفایل دۆزرایەوە'               : 'Profile found';
  String get qrScanError         => isKurdish ? 'QR کۆدی BIC نییە'               : 'Not a BIC QR code';
  String get shareProfileLabel   => isKurdish ? 'هاوبەشکردنی پرۆفایل'             : 'Share Profile';
  String get copyLink            => isKurdish ? 'کۆپیکردنی لینک'                  : 'Copy Link';
  String get linkCopied          => isKurdish ? 'لینک کۆپیکرا ✅'                 : 'Link copied ✅';
  String get shareProfileMsg     => isKurdish ? 'پرۆفایلەکەم لە BIC ببینە:\n@'     : 'See my profile on BIC:\n@';

  // ── Analytics Dashboard ──────────────────────────────────────
  String get analyticsTitle      => isKurdish ? 'داشبۆردی ئامار'                : 'Analytics';
  String get analyticsSub        => isKurdish ? 'ئامارەکانی بیزنەسەکەت'         : 'Your business stats';
  String get period7d            => isKurdish ? '٧ ڕۆژ'                         : '7 days';
  String get period30d           => isKurdish ? '٣٠ ڕۆژ'                        : '30 days';
  String get periodAll           => isKurdish ? 'هەموو'                          : 'All time';
  String get totalViews          => isKurdish ? 'کۆی بینراوەکان'                : 'Total Views';
  String get totalLikes          => isKurdish ? 'کۆی لایکەکان'                  : 'Total Likes';
  String get totalComments       => isKurdish ? 'کۆی کۆمێنتەکان'               : 'Total Comments';
  String get totalFollowers      => isKurdish ? 'فۆڵۆوەرەکان'                   : 'Followers';
  String get engagementChart     => isKurdish ? 'کارایی پۆستەکان'               : 'Post Performance';
  String get engagementChartSub  => isKurdish ? 'لایک + کۆمێنت بۆ هەر پۆستێک' : 'Likes + Comments per post';
  String get topPosts            => isKurdish ? 'باشترین پۆستەکان'              : 'Top Posts';
  String get topPostsSub         => isKurdish ? 'بەپێی کارایی'                  : 'By engagement';
  String get ratingOverview      => isKurdish ? 'خوێندنەوەی نرخاندن'            : 'Rating Overview';
  String get analyticsEmpty      => isKurdish ? 'پۆستێک بنووسە تا ئامار ببینی' : 'Publish posts to see your analytics';
  String get vsLastPeriod        => isKurdish ? 'بەراورد بە پێشوو'              : 'vs last period';
  String get engagementRate      => isKurdish ? 'ڕێژەی کارایی'                  : 'Eng. Rate';
  String get newFollowers        => isKurdish ? 'فۆڵۆوەری تازە'                 : 'New Followers';

  // ── Rating & Reviews ─────────────────────────────────────────
  String get ratingsTitle        => isKurdish ? 'هەڵسەنگاندن و ڕای بەکارهێنەران' : 'Ratings & Reviews';
  String get ratingOverall       => isKurdish ? 'نرخاندنی گشتی'                   : 'Overall Rating';
  String get ratingCount         => isKurdish ? 'هەڵسەنگاندن'                     : 'reviews';
  String get noRatings           => isKurdish ? 'هێشتا هیچ هەڵسەنگاندنێک نییە'   : 'No reviews yet';
  String get noRatingsSub        => isKurdish ? 'یەکەمین کەس بە تکایە ڕایت بدە' : 'Be the first to write a review';
  String get writeReview         => isKurdish ? 'ڕای بنووسە'                      : 'Write a Review';
  String get editReview          => isKurdish ? 'دەستکاریی ڕای'                   : 'Edit Review';
  String get yourRating          => isKurdish ? 'هەڵسەنگاندنت'                    : 'Your Rating';
  String get yourReview          => isKurdish ? 'ڕایت'                            : 'Your Review';
  String get reviewHint          => isKurdish ? 'ڕایت لەسەر ئەم بیزنەسە بنووسە...' : 'Share your experience with this business...';
  String get ratingRequired      => isKurdish ? 'تکایە ستێرەیەک هەڵبژێرە'        : 'Please select a star rating';
  String get reviewSubmitted     => isKurdish ? 'سوپاس، ڕایەکەت تۆمار کرا ✅'    : 'Thank you, your review was submitted ✅';
  String get reviewDeleted       => isKurdish ? 'ڕایەکەت سڕایەوە'                 : 'Your review was deleted';
  String get deleteReviewConfirm => isKurdish ? 'دڵنیایت لە سڕینەوەی ڕایەکەت؟'  : 'Delete your review?';
  String get submitReview        => isKurdish ? 'تۆمارکردن'                       : 'Submit';
  String get ratingLabel1        => isKurdish ? 'زۆر خراپ'  : 'Terrible';
  String get ratingLabel2        => isKurdish ? 'خراپ'       : 'Bad';
  String get ratingLabel3        => isKurdish ? 'باش'        : 'OK';
  String get ratingLabel4        => isKurdish ? 'زۆر باش'   : 'Good';
  String get ratingLabel5        => isKurdish ? 'نایاب'      : 'Excellent';

  // ── General ──────────────────────────────────────────────────
  String get ok             => isKurdish ? 'باشە'                : 'OK';
  String get yes            => isKurdish ? 'بەڵێ'                : 'Yes';
  String get no             => isKurdish ? 'نەخێر'               : 'No';
  String get errorLabel     => isKurdish ? 'هەڵە'                : 'Error';
  String get successLabel   => isKurdish ? 'سەرکەوتوو'           : 'Success';
  String get loading        => isKurdish ? 'بارکردن...'          : 'Loading...';
  String get send           => isKurdish ? 'ناردن'               : 'Send';
  String get editLabel      => isKurdish ? 'دەستکاری'            : 'Edit';
  String get deleteLabel    => isKurdish ? 'سڕینەوە'             : 'Delete';
  String get close          => isKurdish ? 'داخستن'              : 'Close';
  String get back           => isKurdish ? 'گەڕانەوە'            : 'Back';
  String get next           => isKurdish ? 'دواتر'               : 'Next';
  String get done           => isKurdish ? 'تەواو'               : 'Done';
}
