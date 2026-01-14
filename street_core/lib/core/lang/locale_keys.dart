/// Centralized translation keys for the Street Core application.
///
/// This class provides static constants for all translation keys,
/// enabling type safety and autocomplete support throughout the codebase.
///
/// Generated automatically to match the keys in the translation files.
class LocaleKeys {
  LocaleKeys._();

  // ===========================================================================
  // 1. CORE & NAVIGATION
  // ===========================================================================
  
  // App Basic
  static const String appTitle = 'app.title';
  static const String appName = 'app.name';
  static const String appDescription = 'app.description';
  static const String appTagline = 'app.tagline';
  static const String discoverPlatform = 'discover.platform';
  
  // Basic Navigation
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String dashboardTitle = 'dashboard.title';
  static const String back = 'back';
  static const String backPage = 'back.page';
  static const String next = 'next';
  static const String nextPage = 'next.page';
  static const String previous = 'previous';
  static const String goBack = 'go.back';
  static const String backToHome = 'back.to.home';
  static const String backToLogin = 'back.to.login';
  static const String close = 'close';
  static const String open = 'open';
  static const String enter = 'enter';

  // Common Actions
  static const String apply = 'apply';
  static const String save = 'save';
  static const String saveChanges = 'save.changes';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String confirmDelete = 'confirm.delete';
  static const String create = 'create';
  static const String add = 'add';
  static const String remove = 'remove';
  static const String update = 'update';
  static const String cancel = 'cancel';
  static const String confirm = 'confirm';
  static const String submit = 'submit';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String refresh = 'refresh';
  static const String reload = 'reload';
  static const String reset = 'reset';
  static const String retry = 'retry';
  static const String clear = 'clear';
  static const String share = 'share';
  static const String publish = 'publish';
  static const String discard = 'discard';
  static const String retake = 'retake';
  static const String done = 'done';
  static const String ok = 'ok';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String accept = 'accept';
  static const String reject = 'reject';
  static const String approve = 'approve';
  static const String show = 'show';
  static const String hide = 'hide';
  static const String start = 'start';
  static const String end = 'end';
  static const String submitted = 'submitted';
  static const String postpone = 'postpone';
  static const String viewAll = 'view.all';
  static const String viewDetails = 'view.details';
  static const String tapToRetry = 'tap.to.retry';
  static const String submitAndNext = 'submit.and.next';

  // UI States & Indicators
  static const String active = 'active';
  static const String activeOutOfTotal = 'active.out.of.total';
  static const String inactive = 'inactive';
  static const String success = 'success';
  static const String error = 'error';
  static const String warning = 'warning';
  static const String info = 'info';
  static const String loading = 'loading';
  static const String pleaseWait = 'please.wait';
  static const String loadingEllipsis = 'loading...';
  static const String loadingOptions = 'loading.options';
  static const String notFound = 'not.found';
  static const String unauthorized = 'unauthorized';
  static const String forbidden = 'forbidden';
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String registered = 'registered';
  static const String rejected = 'rejected';
  static const String withdrawn = 'withdrawn';
  static const String draft = 'draft';
  static const String total = 'total';
  static const String noData = 'no.data';
  static const String noContentAvailable = 'no.content.available';
  static const String toDefine = 'to.define';
  static const String closed = 'closed';
  static const String status = 'status';
  static const String completed = 'completed';
  static const String unknownState = 'unknown.state';
  static const String free = 'free';
  static const String pageNotFound = 'page.not.found';
  static const String pageNotFoundMessage = 'page.not.found.message';
  static const String viewList = 'view.list';
  static const String viewGrid = 'view.grid';
  static const String hideFilters = 'hide.filters';
  static const String showFilters = 'show.filters';
  static const String noResultsFound = 'no.results.found';
  static const String tryDifferentSearch = 'try.different.search';
  static const String all = 'all';
  static const String selectDate = 'select.date';
  static const String selectTime = 'select.time';
  static const String max = 'max';
  static const String duration = 'duration';

  // ===========================================================================
  // 2. FORMS & VALIDATION
  // ===========================================================================

  static const String title = 'title';
  static const String description = 'description';
  static const String basicInfo = 'basic.info';
  static const String optional = 'optional';
  static const String requiredField = 'required.field';
  static const String fieldRequired = 'field.required';
  static const String isRequired = 'is.required';
  static const String completeThisField = 'complete.this.field';
  static const String incompleteFields = 'incomplete.fields';
  static const String thereAreEmptyFields = 'there.are.empty.fields';
  static const String thereIsFieldWithError = 'there.is.a.field.with.an.error';
  static const String pleaseCheckFields = 'please.check.fields';
  static const String minLength = 'min.length';
  static const String maxLength = 'max.length';
  static const String haveBetween = 'have.between';
  static const String addNumber = 'add.number';
  static const String onlyNumberDouble = 'only.number.double';
  static const String digits = 'digits';
  static const String invalidEmail = 'invalid.email';
  static const String invalidPhone = 'invalid.phone';
  static const String errorRequiredField = 'error.required.field';
  static const String passwordsDontMatch = 'passwords.dont.match';
  static const String emailRequired = 'email.required';
  static const String nameRequired = 'name.required';
  static const String userIdRequired = 'user.id.required';
  static const String invalidUserId = 'invalid.user.id';
  static const String currentPassword = 'current.password';
  static const String newPassword = 'new.password';
  static const String confirmPassword = 'confirm.password';
  static const String passwordMinLength = 'password.min.length';
  static const String passwordHasUppercase = 'password.has.uppercase';
  static const String passwordHasLowercase = 'password.has.lowercase';
  static const String passwordHasNumber = 'password.has.number';
  static const String passwordHasSpecial = 'password.special';
  static const String passwordWeak = 'password.weak';
  static const String passwordMedium = 'password.medium';
  static const String passwordStrong = 'password.strong';
  static const String passwordVeryStrong = 'password.very.strong';
  static const String enterYourName = 'enter.your.name';
  static const String enterYourEmail = 'enter.your.email';
  static const String enterYourPhone = 'enter.your.phone';
  static const String subject = 'subject';
  static const String enterSubject = 'enter.subject';
  static const String selectCategory = 'select.category';
  static const String message = 'message';
  static const String writeYourMessage = 'write.your.message';
  static const String changeYourPassword = 'change.your.password';
  static const String passwordChangeDescription = 'password.change.description';
  static const String securityTips = 'security.tips';
  static const String selectDateTime = 'select.date.time';

  // Selection & Dropdowns
  static const String select = 'select';
  static const String selectAll = 'select.all';
  static const String deselect = 'deselect';
  static const String selectedCount = 'selected.count';
  static const String selectOption = 'select.option';
  static const String selectOptions = 'select.options';
  static const String selectItems = 'select.items';
  static const String dropdownSelector = 'dropdown.selector';
  static const String noOptions = 'no.options';
  static const String noOptionsAvailable = 'no.options.available';
  static const String noOptionsSelected = 'no.options.selected';
  static const String doubleTapToOpenDropdown = 'double.tap.to.open.dropdown';
  static const String dropdownDisabled = 'dropdown.disabled';

  // Special Fields
  static const String city = 'city';
  static const String country = 'country';
  static const String type = 'type';
  static const String name = 'name';
  static const String category = 'category';
  static const String venue = 'venue';
  static const String location = 'location';
  static const String dates = 'dates';
  static const String startDateLabel = 'start.date';
  static const String endDateLabel = 'end.date';
  static const String startTime = 'start.time';
  static const String endTime = 'end.time';
  static const String startTimeBeforeEndTime = 'start.time.before.end.time';
  static const String discipline = 'discipline';
  static const String disciplines = 'disciplines';
  static const String disciplineInline = 'disciplines.inline';
  static const String motocross = 'motocross';
  static const String skateboarding = 'skateboarding';
  static const String bmx = 'bmx';
  static const String scooter = 'scooter';
  static const String inline = 'inline';
  static const String rally = 'rally';
  static const String atv = 'atv';
  static const String equestrian = 'equestrian';
  static const String enduro = 'enduro';
  static const String trial = 'trial';
  static const String supermoto = 'supermoto';
  static const String roadRacing = 'road_racing';
  static const String dirtTrack = 'dirt_track';
  static const String freestyle = 'freestyle';
  static const String currency = 'currency';
  static const String selectCurrency = 'select.currency';

  // ===========================================================================
  // 3. AUTHENTICATION & ACCOUNT
  // ===========================================================================

  // Login/Logout
  static const String logIn = 'log.in';
  static const String logOut = 'log.out';
  static const String googleLogIn = 'google.log.in';
  static const String loginSuccessful = 'login.successful';
  static const String loggedInSuccessfully = 'logged.in.successfully';
  static const String logoutSuccessful = 'logout.successful';
  static const String loginRequired = 'login.required';
  static const String loginToRegisterCompetition = 'login.to.register.competition';
  
  // Registration
  static const String createAccount = 'create.account';
  static const String register = 'register';
  static const String registerSuccessful = 'register.successful';
  static const String successRegister = 'success.register';
  static const String registeredSuccessfully = 'registered.successfully';
  static const String alreadyHaveAccount = 'already.have.account';
  static const String noAccountYet = 'no.account.yet';
  static const String initializing = 'initializing';
  static const String checkingAuthentication = 'checking.authentication';
  static const String authenticated = 'authenticated';
  static const String unauthenticated = 'unauthenticated';
  
  // Password Management
  static const String password = 'password';
  static const String passwordField = 'password.field';
  static const String repeatPassword = 'repeat.password';
  static const String repeatPasswordField = 'repeat.password.field';
  static const String newPasswordField = 'new.password.field';
  static const String changePassword = 'change.password';
  static const String passwordChanged = 'password.changed';
  static const String passwordChangedSuccessfully = 'password.changed.successfully';
  static const String forgotPassword = 'forgot.password';
  static const String resetPassword = 'reset.password';
  static const String passwordResetSent = 'password.reset.sent';
  static const String writeYourPassword = 'write.your.password';
  static const String showPassword = 'show.password';
  static const String hidePassword = 'hide.password';
  static const String originalPasswordNotProvided = 'original.password.not.provided';
  static const String passwordRequirements = 'password.requirements';
  static const String passwordStrengthIndicator = 'password.strength.indicator';
  
  // Email Verification
  static const String checkEmail = 'check.email';
  static const String checkEmailInfo = 'check.email.info';
  static const String enterEmail = 'enter.email';
  static const String errorSendingEmail = 'error.sending.email';
  
  // Policies & Terms (Auth UI)
  static const String acceptPoliciesRequired = 'accept.policies.required';
  static const String iHaveReadAndAccept = 'i.have.read.and.accept';
  static const String pleaseReadAndAccept = 'please.read.and.accept';
  static const String byAcceptingYouAgree = 'by.accepting.you.agree';
  static const String termsAndPolicies = 'terms.and.policies';
  static const String policiesAccepted = 'policies.accepted';

  // Landing Page
  static const String joinUsToday = 'join.us.today';
  static const String startYourJourney = 'start.your.journey';
  static const String getStarted = 'get.started';
  static const String findYourNextAdventure = 'find.your.next.adventure';

  // Greetings
  static const String goodMorning = 'good.morning';
  static const String goodAfternoon = 'good.afternoon';
  static const String goodEvening = 'good.evening';

  // ===========================================================================
  // 4. PROFILE & SOCIAL
  // ===========================================================================

  // Profile Information
  static const String profile = 'profile';
  static const String editProfile = 'edit.profile';
  static const String viewProfile = 'view.profile';
  static const String myProfile = 'my.profile';
  static const String updateProfile = 'update.profile';
  static const String profileUpdated = 'profile.updated';
  static const String profileUpdatedSuccessfully = 'profile.updated.successfully';
  static const String profileUpdateError = 'profile.update.error';
  static const String noUserData = 'no.user.data';
  static const String fullName = 'full.name';
  static const String firstName = 'first.name';
  static const String lastName = 'last.name';
  static const String nickName = 'nick.name';
  static const String bio = 'bio';
  static const String website = 'website';
  static const String gender = 'gender';
  static const String selectGender = 'select.gender';
  static const String phone = 'phone';
  static const String dateOfBirth = 'date.of.birth';
  static const String nationality = 'nationality';
  static const String userDefaultName = 'user.default.name';
  static const String countryOfBorn = 'country.of.born';
  static const String selectCountry = 'select.country';
  static const String loadingAllCountries = 'loading.all.countries';
  static const String countryName = 'country.name';
  static const String cityName = 'city.name';
  static const String address = 'address';
  static const String streetAddress = 'street.address';

  // Gender Options
  static const String male = 'male';
  static const String female = 'female';
  static const String other = 'other';
  static const String preferNotSay = 'prefer.not.say';

  // Account Actions
  static const String accountInformation = 'account.information';
  static const String deleteAccount = 'delete.account';
  static const String deleteAccountConfirmation = 'delete.account.confirmation';
  static const String removeAccountInfo = 'remove.account.info';
  static const String accountDeletedSuccessfully = 'account.deleted.successfully';
  static const String enterFirstName = 'enter.first.name';
  static const String enterLastName = 'enter.last.name';
  static const String addName = 'add.name';
  static const String enterNickname = 'enter.nickname';
  static const String enterBio = 'enter.bio';
  static const String addUserStatName = 'add.user.name';
  static const String enterPhone = 'enter.phone';
  static const String inputHintPhoneNumber = 'input.hint.phone.number';

  // Social Connections
  static const String follow = 'follow';
  static const String unfollow = 'unfollow';
  static const String userFollowed = 'user.followed';
  static const String userUnfollowed = 'user.unfollowed';
  static const String followers = 'followers';
  static const String following = 'following';
  static const String searchFollowers = 'search.followers';
  static const String searchFollowing = 'search.following';
  static const String noFollowersYet = 'no.followers.yet';
  static const String notFollowingAnyoneYet = 'not.following.anyone.yet';
  static const String blockedUsers = 'blocked.users';
  static const String blockedUsersCount = 'blocked.users.count';
  static const String noBlockedUsers = 'no.blocked.users';
  static const String unblockUser = 'unblock.user';
  static const String unblockUserConfirmation = 'unblock.user.confirmation';
  static const String unblock = 'unblock';
  static const String userUnblocked = 'user.unblocked';

  // Posts
  static const String post = 'post';
  static const String posts = 'posts';
  static const String feed = 'feed';
  static const String createPost = 'create.post';
  static const String creatingPost = 'creating.post';
  static const String editPost = 'edit.post';
  static const String deletePost = 'delete.post';
  static const String deletePostConfirmation = 'delete.post.confirmation';
  static const String sharePost = 'share.post';
  static const String shareViaMessage = 'share.via.message';
  static const String noPostsYet = 'no.posts.yet';
  static const String createFirstPost = 'create.first.post';
  static const String shareYourFirstPost = 'share.your.first.post';
  static const String savedPosts = 'saved.posts';
  static const String noSavedPosts = 'no.saved.posts';
  static const String postsSavedAppearHere = 'posts.saved.appear.here';
  static const String postUnsaved = 'post.unsaved';
  static const String removeFromSaved = 'remove.from.saved';
  static const String postActionSuccess = 'post.action.success';
  static const String postError = 'post.error';
  static const String postCreated = 'post.created';
  static const String public = 'public';
  static const String private = 'private';
  static const String visibility = 'visibility';
  static const String errorLoadingPosts = 'error.loading.posts';
  static const String noPostsAvailable = 'no.posts.available';
  static const String featureComingSoon = 'feature.coming.soon';
  static const String errorRemovingPost = 'error.removing.post';
  static const String viewSavedPosts = 'view.saved.posts';
  static const String linkCopied = 'link.copied';
  static const String tagged = 'tagged';
  static const String saved = 'saved';
  static const String highlights = 'highlights';
  static const String highlight = 'highlight';
  static const String whatAreYouThinking = 'what.are.you.thinking';
  static const String mentions = 'mentions';
  static const String hashtags = 'hashtags';
  
  // Profile Extra
  static const String invalidUploadResponse = 'invalid.upload.response';
  static const String avatarUploadedSuccessfully = 'avatar.uploaded.successfully';
  static const String errorUploadingAvatar = 'error.uploading.avatar';
  static const String taggedPostsComingSoon = 'tagged.posts.coming.soon';
  static const String tapBelowToViewSaved = 'tap.below.to.view.saved';
  static const String shareFeatureComingSoon = 'share.feature.coming.soon';

  // Comments
  static const String comment = 'comment';
  static const String comments = 'comments';
  static const String commentAdded = 'comment.added';
  static const String noCommentsYet = 'no.comments.yet';
  static const String deleteComment = 'delete.comment';
  static const String deleteCommentConfirmation = 'delete.comment.confirmation';
  static const String likesResult = 'likes.result';
  static const String viewReply = 'view.reply';
  static const String viewReplies = 'view.replies';
  static const String reply = 'reply';

  // Stories
  static const String addStory = 'add.story';
  static const String addHistory = 'add.history';

  // ===========================================================================
  // 5. MEDIA & UPLOAD
  // ===========================================================================

  // Standard Media Selection
  static const String mediaSelectFiles = 'media.select.files';
  static const String mediaSelectFile = 'media.select.file';
  static const String mediaSelectImage = 'media.select.image';
  static const String mediaSelectImages = 'media.select.images';
  static const String mediaSelectVideo = 'media.select.video';
  static const String mediaSelectSource = 'media.select.source';
  static const String mediaSelectTapToSelect = 'media.select.tap.to.select';
  static const String mediaSelectTapToChooseGallery = 'media.select.tap.to.choose.gallery';
  static const String mediaSelectTapToChooseCamera = 'media.select.tap.to.choose.camera';
  static const String mediaSelectAddMore = 'media.select.add.more';
  static const String mediaSelectSelectingFiles = 'media.select.selecting.files';
  static const String mediaSelectTakePhoto = 'media.select.take.photo';
  static const String mediaSelectFromGallery = 'media.select.from.gallery';
  static const String mediaSelectCamera = 'media.select.camera';
  static const String mediaSelectGallery = 'media.select.gallery';

  // Legacy/Common Labels (Merged from Image Upload)
  static const String takePhoto = 'take.photo';
  static const String chooseFromGallery = 'choose.from.gallery';
  static const String selectFromGallery = 'select.from.gallery';
  static const String changeProfilePhoto = 'change.Profile.Photo';
  static const String confirmChangePhoto = 'confirm.Change.Photo';
  static const String removePhoto = 'remove.photo';

  // Upload Actions & States
  static const String mediaUploadUpload = 'media.upload.upload';
  static const String mediaUploadImage = 'media.upload.image';
  static const String mediaUploadVideo = 'media.upload.video';
  static const String mediaUploadAvatar = 'media.upload.avatar';
  static const String mediaUploadFiles = 'media.upload.files';
  static const String mediaUploadCancel = 'media.upload.cancel';
  static const String mediaUploadRetry = 'media.upload.retry';
  static const String mediaUploadSelectFile = 'media.upload.select.file';
  static const String mediaUploadSelectFiles = 'media.upload.select.files';
  static const String mediaUploadDropFiles = 'media.upload.drop.files';
  static const String mediaUploadOrClick = 'media.upload.or.click';
  static const String mediaUploadUploading = 'media.upload.uploading';
  static const String mediaUploadUploadingImage = 'media.upload.uploading.image';
  static const String mediaUploadUploadingVideo = 'media.upload.uploading.video';
  static const String mediaUploadUploadingAvatar = 'media.upload.uploading.avatar';
  static const String mediaUploadUploadingFiles = 'media.upload.uploading.files';
  static const String mediaUploadProcessing = 'media.upload.processing';
  static const String mediaUploadProgress = 'media.upload.progress';
  static const String mediaUploadComplete = 'media.upload.complete';
  static const String mediaUploadSuccessful = 'media.upload.successful';
  static const String mediaUploadSuccess = 'media.upload.success';
  static const String mediaUploadFailed = 'media.upload.failed';
  static const String mediaUploadCancelled = 'media.upload.cancelled';
  static const String mediaUploadFileUploaded = 'media.upload.file.uploaded';
  static const String mediaUploadFilesUploaded = 'media.upload.files.uploaded';
  static const String mediaUploadFilesUploadedCount = 'media.upload.files.uploaded.count';
  static const String mediaUploadImageUploaded = 'media.upload.image.uploaded';
  static const String mediaUploadVideoUploaded = 'media.upload.video.uploaded';
  
  // Comment States
  static const String edited = 'edited';

  // Avatar Specific
  static const String mediaAvatarUpdated = 'media.avatar.updated';
  static const String mediaAvatarUpload = 'media.avatar.upload';
  static const String mediaAvatarUploadDesc = 'media.avatar.upload.desc';
  static const String mediaAvatarUploadSuccess = 'media.avatar.upload.success';
  static const String mediaAvatarUploading = 'media.avatar.uploading';
  static const String mediaAvatarUrl = 'media.avatar.url';
  static const String mediaAvatarSelect = 'media.avatar.select';
  static const String mediaAvatarChange = 'media.avatar.change';
  static const String mediaAvatarRemove = 'media.avatar.remove';
  static const String mediaAvatarCurrent = 'media.avatar.current';

  // Image Specific
  static const String mediaImageSelect = 'media.image.select';
  static const String mediaImageSelectMultiple = 'media.image.select.multiple';
  static const String mediaImageChange = 'media.image.change';
  static const String mediaImageFromCamera = 'media.image.from.camera';
  static const String mediaImageFromGallery = 'media.image.from.gallery';
  static const String mediaImageUpload = 'media.image.upload';
  static const String mediaImageUploading = 'media.image.uploading';
  static const String mediaImageUploaded = 'media.image.uploaded';
  static const String mediaImageProcessing = 'media.image.processing';
  static const String mediaImageUrl = 'media.image.url';

  // Video Specific
  static const String mediaVideoSelect = 'media.video.select';
  static const String mediaVideoUpload = 'media.video.upload';
  static const String mediaVideoUploading = 'media.video.uploading';
  static const String mediaVideoUploaded = 'media.video.uploaded';
  static const String mediaVideoRecording = 'media.video.recording';
  static const String mediaVideoUrl = 'media.video.url';

  // Media Errors
  static const String mediaErrorNoFilesSelected = 'media.error.no.files.selected';
  static const String mediaErrorSelectingFiles = 'media.error.selecting.files';
  static const String mediaMax = 'media.max';
  static const String mediaErrorSelectingImage = 'media.error.selecting.image';
  static const String mediaErrorReadingFile = 'media.error.reading.file';
  static const String mediaErrorFileTooLarge = 'media.error.file.too.large';
  static const String mediaErrorFileTooSmall = 'media.error.file.too.small';
  static const String mediaErrorImageTooLarge = 'media.error.image.too.large';
  static const String mediaErrorVideoTooLarge = 'media.error.video.too.large';
  static const String mediaErrorAvatarTooLarge = 'media.error.avatar.too.large';
  static const String mediaErrorTotalSizeExceeded = 'media.error.total.size.exceeded';
  static const String mediaErrorAllFilesTooLarge = 'media.error.all.files.too.large';
  static const String mediaErrorTooManyFiles = 'media.error.too.many.files';
  static const String mediaErrorNoValidFiles = 'media.error.no.valid.files';
  static const String mediaErrorMaxFilesExceeded = 'media.error.max.files.exceeded';
  static const String mediaErrorInvalidFileType = 'media.error.invalid.file.type';
  static const String mediaErrorInvalidMimeType = 'media.error.invalid.mime.type';
  static const String mediaErrorInvalidImageFormat = 'media.error.invalid.image.format';
  static const String mediaErrorInvalidVideoFormat = 'media.error.invalid.video.format';
  static const String mediaErrorInvalidExtension = 'media.error.invalid.extension';
  static const String mediaErrorInvalidDimensions = 'media.error.invalid.dimensions';
  static const String mediaErrorDimensionsTooSmall = 'media.error.dimensions.too.small';
  static const String mediaErrorDimensionsTooLarge = 'media.error.dimensions.too.large';
  static const String mediaErrorValidationFailed = 'media.error.validation.failed';
  static const String mediaErrorUploadFailed = 'media.error.upload.failed';
  static const String mediaErrorUploadTimeout = 'media.error.upload.timeout';
  static const String mediaErrorNetworkError = 'media.error.network.error';
  static const String mediaErrorDeleteFailed = 'media.error.delete.failed';
  static const String mediaErrorUnknown = 'media.error.unknown';

  // File Details
  static const String mediaFileSelected = 'media.file.selected';
  static const String mediaFileFilesSelected = 'media.file.files.selected';
  static const String mediaFileFile = 'media.file.file';
  static const String mediaFileFiles = 'media.file.files';
  static const String mediaFileSize = 'media.file.size';
  static const String mediaFileCount = 'media.file.count';
  static const String mediaFileCalculatingSize = 'media.file.calculating.size';
  static const String mediaFilePreview = 'media.file.preview';
  static const String mediaFileRemove = 'media.file.remove';
  static const String mediaFileUploaded = 'media.file.uploaded';
  static const String mediaFileDropHere = 'media.file.drop.here';

  // Media Info & Limits
  static const String mediaInfoMaxFiles = 'media.info.max.files';
  static const String mediaInfoMaxSize = 'media.info.max.size';
  static const String mediaInfoEach = 'media.info.each';
  static const String mediaInfoUploadedImageUrl = 'media.info.uploaded.image.url';
  static const String mediaInfoUploadedVideoUrl = 'media.info.uploaded.video.url';
  static const String mediaInfoUploadedImages = 'media.info.uploaded.images';
  static const String mediaInfoPhotoUrl = 'media.info.photo.url';
  static const String mediaInfoFilesUploaded = 'media.info.files.uploaded';
  static const String mediaInfoSomeFilesSkipped = 'media.info.some.files.skipped';
  static const String mediaInfoCalculatingSize = 'media.info.calculating.size';
  static const String mediaInfoSelectingFiles = 'media.info.selecting.files';
  static const String mediaLimitsMaxSize = 'media.limits.max.size';
  static const String mediaLimitsMaxFiles = 'media.limits.max.files';
  static const String mediaLimitsAllowedFormats = 'media.limits.allowed.formats';

  // Camera Specific
  static const String mediaCameraTakePhoto = 'media.camera.take.photo';
  static const String mediaCameraCapture = 'media.camera.capture';
  static const String mediaCameraCaptureDesc = 'media.camera.capture.desc';

  // Common Actions (Media)
  static const String mediaActionDiscard = 'media.action.discard';
  static const String mediaActionRetake = 'media.action.retake';
  static const String mediaActionDone = 'media.action.done';
  static const String mediaActionCancel = 'media.action.cancel';
  static const String mediaActionRetry = 'media.action.retry';

  // Validation Hints
  static const String mediaValidationChecking = 'media.validation.checking';
  static const String mediaValidationInvalid = 'media.validation.invalid';
  static const String mediaValidationValid = 'media.validation.valid';
  static const String mediaHintSelectFiles = 'media.hint.select.files';
  static const String mediaHintTapToSelect = 'media.hint.tap.to.select';
  static const String mediaHintFilesSelected = 'media.hint.files.selected';
  static const String mediaHintFileSelected = 'media.hint.file.selected';
  static const String mediaHintAddMore = 'media.hint.add.more';
  static const String mediaHintMaxInfo = 'media.hint.max.info';
  static const String errorSelectingImage = 'error.selecting.image';

  // ===========================================================================
  // 6. FEATURES (COMPETITIONS, TOURNAMENTS, EVENTS)
  // ===========================================================================

  // Competitions Basic
  static const String competitions = 'competitions';
  static const String competition = 'competition';
  static const String competitionsTitle = 'competitions.title';
  static const String competitionTitle = 'competition.title';
  static const String competitionDetails = 'competition.details';
  static const String competitionsDashboard = 'competitions.dashboard';
  static const String competitionsWelcome = 'competitions.welcome';
  static const String competitionsDashboardSubtitle = 'competitions.dashboard.subtitle';
  static const String competitionsFeatured = 'competitions.featured';
  static const String competitionsViewAll = 'competitions.view.all';
  static const String competitionsNoFeatured = 'competitions.no.featured';
  static const String competitionsQuickActions = 'competitions.quick.actions';
  static const String competitionsMyCompetitions = 'competitions.my.competitions';
  static const String competitionsCreateNew = 'competitions.create.new';
  static const String competitionsJudgeInvitations = 'competitions.judge.invitations';
  static const String competitionsLiveNow = 'competitions.live.now';
  static const String competitionsUpcoming = 'competitions.upcoming';
  static const String competitionsCompleted = 'competitions.completed';
  static const String competitionsStatistics = 'competitions.statistics';
  static const String competitionsStatsActive = 'competitions.stats.active';
  static const String competitionsStatsParticipants = 'competitions.stats.participants';
  static const String competitionsStatsLive = 'competitions.stats.live';
  static const String competitionsStatsUpcoming = 'competitions.stats.upcoming';
  static const String competitionsStatsUnavailable = 'competitions.stats.unavailable';
  static const String competitionsDisciplines = 'competitions.disciplines';
  static const String testWidget = 'test.widget';
  static const String myCompetitions = 'my.competitions';
  static const String allCompetitions = 'all.competitions';
  static const String createCompetition = 'create.competition';
  static const String editCompetition = 'edit.competition';
  static const String manageCompetition = 'manage.competition';
  static const String competitionCreated = 'competition.created.successfully';
  static const String competitionUpdated = 'competition.updated.successfully';
  static const String competitionDeleted = 'competition.deleted.successfully';
  static const String competitionStarted = 'competition.started.successfully';
  static const String competitionEnded = 'competition.ended.successfully';
  static const String competitionPostponed = 'competition.postponed.successfully';
  static const String competitionStatusChanged = 'competition.status.changed';
  static const String competitionStatus = 'competition.status';
  static const String competitionBanner = 'competition.banner';
  static const String competitionType = 'competition.type';
  static const String selectCompetitionType = 'select.competition.type';
  static const String selectFormat = 'select.format';
  static const String selectDiscipline = 'select.discipline';
  static const String categoryClass = 'category.class';
  static const String categoryClassHint = 'category.class.hint';
  static const String bannerImage = 'banner.image';
  static const String competitionRulesHint = 'competition.rules.hint';
  static const String noCompetitionsCreated = 'no.competitions.created';
  static const String createFirstCompetition = 'create.first.competition';
  
  // Competition Format & Details
  static const String format = 'format';
  static const String rounds = 'rounds';
  static const String totalRoundsHint = 'total.rounds.hint';
  static const String firstPlace = 'first.place';
  static const String secondPlace = 'second.place';
  static const String thirdPlace = 'third.place';
  static const String organizer = 'organizer';
  static const String id = 'id';
  static const String club = 'club';
  static const String dateAndLocation = 'date.and.location';
  static const String registrationDeadlineLabel = 'registration.deadline';
  static const String range = 'range';
  static const String points = 'points';
  static const String assigned = 'assigned';
  static const String adjustment = 'adjustment';
  static const String requests = 'requests';
  static const String registeredCount = 'registered.count';
  static const String searchCompetition = 'search.competition';
  static const String shareButton = 'share.button';
  static const String copyLink = 'copy.link';
  static const String shareCompetitionTooltip = 'share.competition.tooltip';
  static const String shareThisCompetition = 'share.this.competition';
  static const String shareCompetitionDescription = 'share.competition.description';
  static const String joinOnFitRidersPro = 'join.on.fit.riders.pro';
  static const String failedToShare = 'failed.to.share';
  static const String failedToCopyLink = 'failed.to.copy.link';
  
  // Location Support
  static const String yourLocation = 'your.location';
  static const String searchLocation = 'search.location';
  static const String showAllLocations = 'show.all.locations';
  static const String selectLocation = 'select.location';
  static const String clearLocation = 'clear.location';
  static const String locationManual = 'location.manual';
  static const String locationAuto = 'location.auto';
  static const String detectLocation = 'detect.location';
  static const String searchCityHint = 'search.city.hint';
  static const String noLocation = 'no.location';
  static const String searchRadius = 'search.radius';


  
  // Competition Modes & Types
  static const String sequentialMode = 'sequential.mode';
  static const String simultaneousMode = 'simultaneous.mode';

  // Tournaments
  static const String tournamentsTitle = 'tournaments.title';
  static const String tournamentsWelcome = 'tournaments.welcome';
  static const String tournamentsDashboardSubtitle = 'tournaments.dashboard.subtitle';
  static const String tournamentsDetail = 'tournaments.detail';
  static const String tournamentsStandings = 'tournaments.standings';
  static const String tournamentsCompetitions = 'tournaments.competitions';
  static const String tournamentsInfo = 'tournaments.info';
  static const String tournamentsDescription = 'tournaments.description';
  static const String tournamentsSchedule = 'tournaments.schedule';
  static const String tournamentsStartDate = 'tournaments.start.date';
  static const String tournamentsEndDate = 'tournaments.end.date';
  static const String tournamentsVenue = 'tournaments.venue';
  static const String tournamentsCountry = 'tournaments.country';
  static const String tournamentsRegistration = 'tournaments.registration';
  static const String tournamentsMaxParticipants = 'tournaments.max.participants';
  static const String tournamentsDeadline = 'tournaments.deadline';
  static const String tournamentsEntryFee = 'tournaments.entry.fee';
  static const String tournamentsPoints = 'tournaments.points';
  static const String tournamentsStatusUpcoming = 'tournaments.status.upcoming';
  static const String tournamentsStatusLive = 'tournaments.status.live';
  static const String tournamentsStatusCompleted = 'tournaments.status.completed';
  static const String tournamentsRegistrationOpen = 'tournaments.registration.open';
  static const String tournamentsNoTournaments = 'tournaments.no.tournaments';
  static const String tournamentsStatistics = 'tournaments.statistics';
  static const String tournamentsScoringSystem = 'tournaments.scoring.system';
  static const String tournamentsSystem = 'tournaments.system';
  static const String tournamentsScoring = 'tournaments.scoring';
  static const String tournamentsCountBest = 'tournaments.count.best';
  static const String tournamentsDropWorst = 'tournaments.drop.worst';
  
  // Tournament Extras
  static const String tournamentFormatsSeries = 'formats.series';
  static const String tournamentFormatsSingle = 'formats.single';
  static const String tournamentFormatsKnockout = 'formats.knockout';
  static const String tournamentScoringPoints = 'tournaments.scoring.points';
  static const String tournamentScoringTime = 'tournaments.scoring.time';
  static const String tournamentScoringBestResult = 'tournaments.scoring.best_result';
  static const String errorSelectDates = 'error.select.dates';
  static const String athletesInHeat = 'athletes.in.heat';
  static const String tournamentsNoStandings = 'tournaments.no.standings';
  static const String tournamentsAthletes = 'tournaments.athletes';
  static const String tournamentsMyTournaments = 'tournaments.my.tournaments';
  static const String tournamentsCreateNew = 'tournaments.create.new';
  static const String tournamentsOrganized = 'tournaments.organized';
  static const String tournamentsParticipating = 'tournaments.participating';
  static const String tournamentsNoOrganized = 'tournaments.no.organized';
  static const String tournamentsCreateFirst = 'tournaments.create.first';
  static const String tournamentsNoParticipating = 'tournaments.no.participating';
  static const String tournamentsNoCompetitions = 'tournaments.no.competitions';
  static const String tournamentsStatus = 'tournaments.status';
  static const String tournamentsEdit = 'tournaments.edit';
  static const String tournamentsId = 'tournaments.id';
  static const String tournamentsQuickActions = 'tournaments.quick.actions';
  static const String tournamentsFeatured = 'tournaments.featured';
  static const String tournamentsViewAll = 'tournaments.view.all';
  static const String tournamentsNoFeatured = 'tournaments.no.featured';
  static const String tournamentsStatsActive = 'tournaments.stats.active';
  static const String tournamentsStatsAthletes = 'tournaments.stats.athletes';
  static const String tournamentsStatsLive = 'tournaments.stats.live';
  static const String tournamentsStatsUpcoming = 'tournaments.stats.upcoming';
  static const String tournamentsStatsUnavailable = 'tournaments.stats.unavailable';
  static const String tournamentsRegister = 'tournaments.register';
  static const String tournamentsUnregister = 'tournaments.unregister';
  static const String tournamentsRegisterConfirm = 'tournaments.register.confirm';
  static const String tournamentsUnregisterConfirm = 'tournaments.unregister.confirm';
  static const String tournamentsRegisterMessage = 'tournaments.register.message';
  static const String tournamentsUnregisterMessage = 'tournaments.unregister.message';
  static const String tournamentsFilters = 'tournaments.filters';
  static const String tournamentsFilterStatus = 'tournaments.filter.status';
  static const String tournamentsFilterDiscipline = 'tournaments.filter.discipline';
  static const String tournamentsFilterYear = 'tournaments.filter.year';

  // Events
  static const String events = 'events';
  static const String eventNotFound = 'event.not.found';
  static const String upcomingEvents = 'upcoming.events';
  static const String calendar = 'calendar';
  static const String eventFull = 'event.full';
  
  // Public Pages
  static const String clubs = 'clubs';
  static const String market = 'market';
  static const String athletes = 'athletes';
  static const String exploreAllRiders = 'explore.all.riders';
  static const String browseClubs = 'browse.clubs';
  static const String browseMarket = 'browse.market';
  static const String browseEvents = 'browse.events';

  // Management & Validation
  static const String managementPanel = 'management.panel';
  static const String validationChecklist = 'validation.checklist';
  static const String statusCheck = 'status.check';
  static const String participantsCheck = 'participants.check';
  static const String categoriesCheck = 'categories.check';
  static const String criteriaCheck = 'criteria.check';
  static const String warnings = 'warnings';
  static const String startCompetitionTitle = 'start.competition.title';
  static const String startCompetitionMessage = 'start.competition.message';
  static const String endCompetitionTitle = 'end.competition.title';
  static const String endCompetitionMessage = 'end.competition.message';
  static const String postponeCompetitionTitle = 'postpone.competition.title';
  static const String postponeCompetitionMessage = 'postpone.competition.message';
  static const String deleteCompetitionTitle = 'delete.competition.title';
  static const String deleteCompetitionMessage = 'delete.competition.message';
  static const String deleteActionIrreversible = 'delete.action.irreversible';
  static const String errorCompetitionNotUpcoming = 'error.competition.not.upcoming';
  static const String errorInsufficientParticipants = 'error.insufficient.participants';
  static const String errorNoCategoriesConfigured = 'error.no.categories.configured';
  static const String errorNoCriteriaConfigured = 'error.no.criteria.configured';
  static const String noDiscipline = 'no.discipline';
  static const String noDraftCompetitions = 'competitions.no.draft.competitions';
  static const String noUpcomingCompetitions = 'competitions.no.upcoming.competitions';
  static const String noLiveCompetitions = 'competitions.no.live.competitions';
  static const String noCompletedCompetitions = 'competitions.no.completed.competitions';
  static const String selectHeat = 'select.heat';
  static const String roundProgress = 'round.progress';
  static const String errorLoadingHeats = 'error.loading.heats';
  static const String athletesCount = 'athletes.count';
  static const String durationMin = 'duration.min';
  static const String startScoring = 'start.scoring';
  static const String viewHeat = 'view.heat';
  static const String categories = 'categories';
  static const String addCategory = 'add.category';
  static const String categoryUpdatedSuccessfully = 'category.updated.successfully';
  static const String tapAddToCreateCategory = 'tap.add.to.create.category';
  static const String confirmDeleteCategory = 'confirm.delete.category';
  
  // Category Info
  static const String noRankingData = 'no.ranking.data';
  static const String averageScore = 'average.score';
  static const String judgesScored = 'judges.scored';
  static const String scoringCriteria = 'scoring.criteria';
  static const String skillLevel = 'skill.level';
  static const String maxJudges = 'max.judges';
  static const String ageRange = 'age.range';
  static const String noCategoriesYet = 'no.categories.yet';
  static const String skillLevelBeginner = 'skill.level.beginner';
  static const String skillLevelIntermediate = 'skill.level.intermediate';
  static const String skillLevelAdvanced = 'skill.level.advanced';
  static const String skillLevelPro = 'skill.level.pro';
  static const String changeTheme = 'change.theme';
  static const String lightMode = 'light.mode';
  static const String darkMode = 'dark.mode';
  static const String selectTheme = 'select.theme';
  static const String imageGallery = 'image.gallery';
  static const String of = 'of';
  static const String images = 'images';
  static const String addFirstImage = 'add.first.image';
  static const String main = 'main';
  static const String image = 'image';
  static const String markAsMain = 'mark.as.main';
  static const String imagesOf = 'images.of';
  static const String imageGalleryCount = 'image.gallery.count';
  static const String mainImageNumber = 'main.image.number';
  static const String imageNumber = 'image.number';
  static const String maxImagesAllowed = 'max.images.allowed';
  static const String pinchToZoom = 'pinch.to.zoom';

  // Management Dialogs
  static const String rejectParticipantTitle = 'reject.participant.title';
  static const String rejectReasonOptional = 'reject.reason.optional';
  static const String rejectReasonHint = 'reject.reason.hint';
  
  // Participant Approval Messages
  static const String participantApproved = 'participant.approved';
  static const String participantRejected = 'participant.rejected';
  static const String participantsApproved = 'participants.approved';
  static const String participantsRejected = 'participants.rejected';
  static const String errorApprovingParticipant = 'error.approving.participant';
  static const String errorRejectingParticipant = 'error.rejecting.participant';
  static const String errorApprovingParticipants = 'error.approving.participants';
  static const String errorRejectingParticipants = 'error.rejecting.participants';
  
  // Timeline
  static const String timelineTitle = 'timeline.title';
  static const String timelineRegistration = 'timeline.registration';
  static const String timelineActive = 'timeline.active';
  static const String timelineCompleted = 'timeline.completed';
  static const String timelineCurrent = 'timeline.current';
  static const String prizes = 'prizes';
  
  // Competition Details
  static const String rules = 'rules';
  static const String requirements = 'requirements';
  static const String venueName = 'venue.name';
  static const String refundPolicy = 'refund.policy';
  static const String dataProtection = 'data.protection';

  // Participants & Registration
  static const String participants = 'participants';
  static const String noParticipants = 'no.participants';
  static const String noParticipantsInCompetition = 'no.participants.in.competition';
  static const String noParticipantsYet = 'no.participants.yet';
  static const String activeParticipants = 'active.participants';
  static const String registration = 'registration';
  static const String registerToCompetition = 'registration';
  static const String deadline = 'deadline';
  static const String entryFee = 'entry.fee';
  static const String unregisteredSuccessfully = 'unregistered.successfully';
  static const String unregister = 'unregister';
  static const String unregisterShort = 'unregister.short';
  static const String confirmRegister = 'confirm.register';
  static const String confirmUnregister = 'confirm.unregister';
  static const String maxParticipants = 'max.participants';
  static const String minParticipants = 'min.participants';
  static const String approvedCount = 'approved.count';
  static const String pendingCount = 'pending.count';
  static const String checkedInCount = 'checked.in.count';
  static const String rejectedCount = 'rejected.count';
  static const String withdrawnCount = 'withdrawn.count';
  static const String participantNumber = 'participant.number';
  static const String registrationNumber = 'registration.number';
  static const String requiresApproval = 'requires.approval';
  static const String requiresApprovalHint = 'requires.approval.hint';
  static const String allParticipants = 'all.participants';
  static const String pendingApproval = 'pending.approval';
  static const String approveSelected = 'approve.selected';
  static const String rejectSelected = 'reject.selected';
  static const String requiresParticipantApproval = 'requires.participant.approval';
  
  // Participants Management
  static const String participant = 'participant';
  static const String participantId = 'participant.id';
  static const String enterParticipantId = 'enter.participant.id';
  static const String addParticipant = 'add.participant';
  static const String removeParticipant = 'remove.participant';
  static const String removeParticipantConfirmation = 'remove.participant.confirmation';
  static const String athlete = 'athlete';
  static const String noParticipantsToScore = 'no.participants.to.score';

  // Judges & Scoring
  static const String judge = 'judge';
  static const String judges = 'judges';
  static const String inviteJudge = 'invite.judge';
  static const String judgesPanel = 'judges.panel';
  static const String judgesPanelComplete = 'judges.panel.complete';
  static const String noJudges = 'no.judges';
  static const String requiredJudges = 'required.judges';
  static const String judgesNeededToStart = 'judges.needed.to.start';
  static const String assignedJudges = 'assigned.judges';
  static const String scoringSystem = 'scoring.system';
  static const String evaluationCriteria = 'evaluation.criteria';
  static const String scoringTypePoints = 'scoring.type.points';
  static const String scoringTypeTime = 'scoring.type.time';
  static const String scoringTypeAverage = 'scoring.type.average';
  static const String scoringTypeSum = 'scoring.type.sum';
  static const String scoringTypeWeightedAverage = 'scoring.type.weighted.average';
  static const String dropHighestScore = 'drop.highest.score';
  static const String dropLowestScore = 'drop.lowest.score';
  static const String totalScore = 'total.score';
  static const String scoreAthlete = 'score.athlete';
  static const String updateScore = 'update.score';
  static const String scoreParticipant = 'score.participant';
  static const String selectScoringType = 'select.scoring.type';
  static const String maxScoreHint = 'max.score.hint';
  static const String scoreAllAthletes = 'score.all.athletes';
  static const String resultsPublished = 'results.published.successfully';
  static const String publishResultsTitle = 'publish.results.title';
  static const String publishResultsMessage = 'publish.results.message';
  static const String leaderboard = 'leaderboard';
  static const String judgeScoring = 'judge.scoring';
  
  // Judges & Participants Management
  static const String noJudgesAssigned = 'no.judges.assigned';
  static const String judgeId = 'judge.id';
  static const String enterJudgeId = 'enter.judge.id';
  static const String removeJudge = 'remove.judge';
  static const String removeJudgeConfirmation = 'remove.judge.confirmation';
  static const String inviteJudgeFab = 'invite.judge.fab';
  static const String judgesMissing = 'judges.missing';
  
  // Judge Status
  static const String myJudgeInvitations = 'my.judge.invitations';
  static const String accepted = 'accepted';
  static const String yourResponse = 'your.response';

  static const String results = 'results';

  // Judge Invitations
  static const String byEmail = 'by.email';
  static const String searchUser = 'search.user';
  static const String externalJudge = 'external.judge';
  static const String inviteByEmailDescription = 'invite.by.email.description';
  static const String email = 'email';
  static const String messageOptional = 'message.optional';
  static const String invitationMessageHint = 'invitation.message.hint';
  static const String searchUserDescription = 'search.user.description';
  static const String usernameOrId = 'username.or.id';
  static const String searchUserHint = 'search.user.hint';
  static const String selectedUser = 'selected.user';
  static const String enterUserIdToInvite = 'enter.user.id.to.invite';
  static const String externalJudgeDescription = 'external.judge.description';
  static const String externalJudgeNameHint = 'external.judge.name.hint';
  static const String externalJudgeInfo = 'external.judge.info';
  static const String sendInvitation = 'send.invitation';
  static const String addJudge = 'add.judge';
  static const String invitationSent = 'invitation.sent';
  static const String externalJudgeAdded = 'external.judge.added';
  static const String invite = 'invite';
  static const String pendingInvitations = 'pending.invitations';
  static const String invitedBy = 'invited.by';
  static const String invitationExpiresAt = 'invitation.expires.at';
  static const String acceptInvitation = 'accept.invitation';
  static const String confirmAcceptInvitation = 'confirm.accept.invitation';
  static const String rejectInvitation = 'reject.invitation';
  static const String confirmRejectInvitation = 'confirm.reject.invitation';
  static const String noInvitations = 'no.invitations';

  // Timeline & Schedule
  static const String timeline = 'timeline';


  // ===========================================================================
  // 7. SETTINGS & PREFERENCES
  // ===========================================================================

  static const String settings = 'settings';
  static const String account = 'account';
  static const String preferences = 'preferences';
  static const String appPreferences = 'app.preferences';
  static const String privacySettings = 'privacy.settings';
  static const String accountSecurity = 'account.security';
  static const String theme = 'theme';
  static const String language = 'language';
  static const String notifications = 'notifications';
  static const String dataUsage = 'data.usage';
  static const String helpCenter = 'help.center';
  static const String howToCreateCompetition = 'how.to.create.competition';
  static const String howToCreateCompetitionDesc = 'how.to.create.competition.desc';
  static const String howToJoinClub = 'how.to.join.club';
  static const String howToJoinClubDesc = 'how.to.join.club.desc';
  static const String contactSupport = 'contact.support';
  static const String support = 'support';
  static const String about = 'about';
  static const String appVersion = 'app.version';
  static const String pushNotifications = 'push.notifications';
  static const String emailNotifications = 'email.notifications';
  static const String enablePush = 'enable.push';
  static const String receivePushDescription = 'receive.push.description';
  static const String enableEmail = 'enable.email';
  static const String receiveEmailDescription = 'receive.email.description';
  static const String marketingEmails = 'marketing.emails';
  static const String receiveMarketingDescription = 'receive.marketing.description';
  static const String mediaAutoDownload = 'media.auto.download';
  static const String storage = 'storage';
  static const String always = 'always';
  static const String wifiOnly = 'wifi.only';
  static const String never = 'never';
  static const String autoplayVideos = 'autoplay.videos';
  static const String downloadWifiOnly = 'download.wifi.only';
  static const String clearCache = 'clear.cache';
  static const String freeUpSpace = 'free.up.space';
  static const String cacheCleared = 'cache.cleared';
  static const String customizeYourExperience = 'customize.your.experience';
  static const String settingsNav = 'settings.nav';
  static const String selectLanguage = 'select.language';
  static const String viewPolicies = 'view.policies';
  static const String viewFullPolicy = 'view.full.policy';
  
  // Privacy Details
  static const String manageYourPrivacy = 'manage.your.privacy';
  static const String profileVisibility = 'profile.visibility';
  static const String whoCanSeeYourProfile = 'who.can.see.your.profile';
  static const String contactInformation = 'contact.information';
  static const String showEmail = 'show.email';
  static const String showEmailDescription = 'show.email.description';
  static const String showPhone = 'show.phone';
  static const String showPhoneDescription = 'show.phone.description';
  static const String showBirthdate = 'show.birthdate';
  static const String showBirthdateDescription = 'show.birthdate.description';
  static const String onlineStatus = 'show.online.status';
  static const String activityFeed = 'show.activity.feed';
  static const String activityPrivacy = 'activity.privacy';
  static const String showOnlineStatus = 'show.online.status';
  static const String showOnlineStatusDescription = 'show.online.status.description';
  static const String showLastSeen = 'show.last.seen';
  static const String showLastSeenDescription = 'show.last.seen.description';
  static const String showActivityFeed = 'show.activity.feed';
  static const String showActivityFeedDescription = 'show.activity.feed.description';
  static const String allowTagging = 'allow.tagging';
  static const String allowTaggingDescription = 'allow.tagging.description';
  static const String allowMentions = 'allow.mentions';
  static const String allowMentionsDescription = 'allow.mentions.description';
  static const String privateAccount = 'private.account';
  static const String privateAccountDescription = 'private.account.description';
  static const String allowDataCollection = 'allow.data.collection';
  static const String allowDataCollectionDescription = 'allow.data.collection.description';
  static const String personalization = 'allow.personalized.ads';
  static const String allowPersonalizedAds = 'allow.personalized.ads';
  static const String allowPersonalizedAdsDescription = 'allow.personalized.ads.description';
  static const String interactionSettings = 'interaction.settings';
  static const String whoCanMessageYou = 'who.can.message.you';
  static const String whoCanMessageYouDescription = 'who.can.message.you.description';
  static const String whoCanComment = 'who.can.comment';
  static const String whoCanCommentDescription = 'who.can.comment.description';
  static const String whoCanFollowYou = 'who.can.follow.you';
  static const String whoCanFollowYouDescription = 'who.can.follow.you.description';
  static const String requireFollowApproval = 'require.follow.approval';
  static const String requireFollowApprovalDescription = 'require.follow.approval.description';
  static const String dataPrivacy = 'data.privacy';
  static const String managePrivacy = 'manage.privacy';
  static const String allowThirdPartySharing = 'allow.third.party.sharing';
  static const String allowThirdPartySharingDescription = 'allow.third.party.sharing.description';
  static const String everyone = 'everyone';
  static const String friends = 'friends';
  static const String nobody = 'nobody';
  static const String user = 'user';

  // Legal & Cookies
  static const String termsOfService = 'terms.of.service';
  static const String privacyPolicy = 'privacy.policy';
  static const String cookiePolicy = 'cookie.policy';
  static const String legalInformation = 'legal.information';
  static const String legalInformationSubtitle = 'legal_information_subtitle';
  static const String toBeDefined = 'to.be.defined';
  static const String respectYourPrivacy = 'we.respect.your.privacy';
  static const String acceptCookiesMessage = 'accept.cookies.message';
  static const String rejectCookies = 'reject.cookies';
  static const String acceptAll = 'accept.all';
  static const String rejectAll = 'reject.all';
  static const String necessaryCookies = 'necessary.cookies';
  static const String analyticsCookies = 'analytics.cookies';
  static const String locationCookies = 'location.cookies';
  static const String marketingCookies = 'marketing.cookies';
  static const String saveSelection = 'save.selection';
  static const String configurationOfPrivacy = 'configuration.of.privacy';

  // ===========================================================================
  // 8. MEASUREMENTS & TIME
  // ===========================================================================

  // Distances & Weight
  static const String distanceKm = 'distance.km';
  static const String distanceM = 'distance.m';
  static const String weightKg = 'weight.kg';
  static const String weightG = 'weight.g';

  // Relative Dates (Time Ago)
  static const String justNow = 'just.now';
  static const String minutesAgo = 'minutes.ago';
  static const String hoursAgo = 'hours.ago';
  static const String daysAgo = 'days.ago';
  static const String weeksAgo = 'weeks.ago';
  static const String monthsAgo = 'months.ago';
  static const String yearsAgo = 'years.ago';
  static const String today = 'today';
  static const String yesterday = 'yesterday';
  static const String tomorrow = 'tomorrow';
  
  // ===========================================================================
  // 8.5 CONTACT & MESSAGING
  // ===========================================================================
  
  static const String contact = 'contact';
  static const String contactInfo = 'contact.info';
  static const String sendMessage = 'send.message';
  static const String contactUs = 'contact.us';
  static const String getInTouch = 'get.in.touch';
  static const String sendUsMessage = 'send.us.message';
  static const String contactMessageSubmitted = 'contact.message.submitted';
  static const String followUs = 'follow.us';
  static const String errorLoadingContact = 'error.loading.contact';
  static const String businessHours = 'business.hours';

  // ===========================================================================
  // 9. SYSTEM, SYNC & ERRORS
  // ===========================================================================

  // General Errors
  static const String errorNetwork = 'error.network';
  static const String errorServerDefault = 'error.server.default';
  static const String errorResourceNotFound = 'error.resource.not.found';
  static const String errorUnauthorized = 'error.unauthorized';
  static const String errorForbidden = 'error.forbidden';
  static const String errorTimeoutRequest = 'error.timeout.request';
  static const String errorTimeoutDownload = 'error.timeout.download';
  static const String errorDownloadFailed = 'error.download.failed';
  static const String errorUnknown = 'error.unknown';
  static const String errorInvalidResponse = 'error.invalid.response';
  static const String serverError = 'server.error';
  static const String validationError = 'validation.error';
  static const String noDataAvailable = 'no.data.available';
  static const String rateLimitExceeded = 'rate.limit.exceeded';
  static const String routeNotFound = 'route.not.found';
  static const String authFailed = 'error.authentication.failed';
  static const String invalidCredentials = 'invalid.credentials';
  static const String userNotFound = 'user.not.found';
  static const String tokenExpired = 'token.expired';
  static const String expired = 'expired';

  // Operations Errors (Unified Patterns used by user)
  static const String errorLoading = 'error.loading.resource';
  static const String errorCreating = 'error.creating.resource';
  static const String errorUpdating = 'error.updating.resource';
  static const String errorDeleting = 'error.deleting.resource';
  static const String errorAdding = 'error.adding.resource';
  static const String errorRemoving = 'error.removing.resource';
  static const String errorAssigningJudge = 'error.assigning.judge';
  static const String errorRemovingJudge = 'error.removing.judge';
  static const String errorReorderingCategories = 'error.reordering.categories';
  static const String errorLoadingScoringMode = 'error.loading.scoring.mode';
  static const String errorInitializationFailed = 'error.initialization.failed';

  // Success Messages (Unified Patterns used by user)
  static const String deletedSuccessfully = 'resource.deleted.successfully';
  static const String addedSuccessfully = 'resource.added.successfully';
  static const String removedSuccessfully = 'resource.removed.successfully';
  static const String judgeAssignedSuccessfully = 'judge.assigned.successfully';
  static const String judgeRemovedSuccessfully = 'judge.removed.successfully';

  // Sync Status
  static const String syncingScores = 'syncing.scores';
  static const String syncError = 'sync.error';
  static const String pendingSyncCount = 'pending.sync.count';
  static const String offlineSyncStatus = 'offline.sync.status';
  static const String pendingScores = 'pending.scores';
  static const String syncStatus = 'sync.status';
  static const String syncing = 'syncing';
  static const String idle = 'idle';
  static const String syncNow = 'sync.now';
  static const String lastError = 'last.error';
  static const String errorLoadingUser = 'error.loading.user';

  // Backend Mappings (Messages.go)
  static const String backendSuccessUserRetrieved = 'user.retrieved';
  static const String backendSuccessProfileUpdated = 'profile.updated';
  static const String backendErrorInvalidInput = 'invalid.input';
  static const String backendErrorInternalServerError = 'internal.server.error';
  
  // Admin & Monitoring
  static const String adminPage = 'admin.page';
  static const String systemMonitoring = 'system.monitoring';
  static const String monitorSystemPerformance = 'monitor.system.performance';
  static const String cacheActions = 'cache.actions';
  static const String cacheClearedSuccessfully = 'cache.cleared.successfully';
  static const String clearAllCache = 'clear.all.cache';
  static const String expiredEntriesCleanedUp = 'expired.entries.cleaned.up';
  static const String cleanupExpired = 'cleanup.expired';
  static const String siteConfigCacheInvalidated = 'site.config.cache.invalidated';
  static const String refreshSiteConfig = 'refresh.site.config';
  static const String aboutCache = 'about.cache';
  static const String cacheSystemDescription = 'cache.system.description';
  static const String cacheRecommendations = 'cache.recommendations';
  static const String hitRateExcellent = 'hit.rate.excellent';
  static const String hitRateGood = 'hit.rate.good';
  static const String hitRateWarning = 'hit.rate.warning';
  static const String utilizationWarning = 'utilization.warning';

  // ===========================================================================
  // 10. LIVESTREAMS
  // ===========================================================================

  static const String createLivestream = 'create.livestream';
  static const String livestreamTitle = 'livestream.title';
  static const String livestreamDescription = 'livestream.description';
  static const String enterLivestreamTitle = 'enter.livestream.title';
  static const String enterLivestreamDescription = 'enter.livestream.description';
  static const String tagsSeparatedByCommas = 'tags.separated.by.commas';
  static const String tagsExample = 'tags.example';
  static const String enableRecording = 'enable.recording';
  static const String recordingDescription = 'recording.description';
  static const String scheduleLivestream = 'schedule.livestream';
  static const String scheduleDescription = 'schedule.description';
  static const String scheduledFor = 'scheduled.for';
  static const String selectDateAndTime = 'select.date.and.time';
  static const String transmit = 'transmit';
  static const String errorLoadingStreams = 'error.loading.streams';
  static const String noLiveStreams = 'no.live.streams';
  static const String beTheFirstToTransmit = 'be.the.first.to.transmit';
  static const String errorLoadingMyStreams = 'error.loading.my.streams';
  static const String noMyStreams = 'no.my.streams';
  static const String searchStreams = 'search.streams';
  static const String typeToSearch = 'type.to.search';
  static const String scheduledTodayAt = 'scheduled.today.at';
  static const String scheduledTomorrowAt = 'scheduled.tomorrow.at';
  static const String scheduledAt = 'scheduled.at';
  static const String livestreamInfoPoints = 'livestream.info.points';
  static const String myStreams = 'my.streams';
  static const String liveNow = 'live.now';
  static const String scheduled = 'scheduled';

  // Stream Stats
  static const String viewers = 'viewers';
  static const String peak = 'peak';
  static const String views = 'views';
  static const String reactions = 'reactions';
  static const String messages = 'messages';

  // ===========================================================================
  // 11. REAL-TIME & EMERGENCY
  // ===========================================================================

  // SSE Connection States
  static const String sseConnected = 'sse.connected';
  static const String sseConnecting = 'sse.connecting';
  static const String sseReconnecting = 'sse.reconnecting';
  static const String sseDisconnected = 'sse.disconnected';
  static const String sseConnectionError = 'sse.connection.error';
  static const String sseLive = 'sse.live';

  // Emergency Event Types
  static const String emergencyScoreReset = 'emergency.score.reset';
  static const String emergencyScoreSwap = 'emergency.score.swap';
  static const String emergencyScoreOverride = 'emergency.score.override';
  static const String emergencyAlert = 'emergency.alert';
  static const String emergencyScoreUnderReview = 'emergency.score.under.review';
  static const String emergencyHeatOrderChange = 'emergency.heat.order.change';
  static const String emergencyAthleteRemoved = 'emergency.athlete.removed';

  // Emergency Messages
  static const String emergencyScoresSwapped = 'emergency.scores.swapped';
  static const String emergencyActionRequired = 'emergency.action.required';
  static const String emergencyAcknowledge = 'emergency.acknowledge';
  static const String emergencyAlertTitle = 'emergency.alert.title';
  static const String emergencySubject = 'emergency.subject';

  // ===========================================================================
  // 12. SPEAKER DASHBOARD & JUDGING
  // ===========================================================================

  // Speaker Dashboard
  static const String speakerDashboard = 'speaker.dashboard';
  static const String speakerDashboardTitle = 'speaker.dashboard.title';
  static const String currentHeat = 'current.heat';
  static const String nextHeat = 'next.heat';
  static const String heatNumber = 'heat.number';
  static const String athletesList = 'athletes.list';
  static const String noHeatsAvailable = 'no.heats.available';
  static const String loadingHeat = 'loading.heat';
  static const String noCategories = 'no.categories';
  static const String reloadData = 'reload.data';
  static const String dataUpdated = 'data.updated';

  // Judge Scoring - Concurrency & Errors
  static const String errorHeatClosed = 'error.heat.closed';
  static const String errorHeatClosedMessage = 'error.heat.closed.message';
  static const String errorScoreConflict = 'error.score.conflict';
  static const String errorScoreConflictMessage = 'error.score.conflict.message';
  static const String errorScoreAlreadyReset = 'error.score.already.reset';
  static const String errorScoreAlreadyResetMessage = 'error.score.already.reset.message';
  static const String errorScoreReset = 'error.score.reset'; // Alias
  static const String errorScoreResetMessage = 'error.score.reset.message'; // Alias
  static const String errorConcurrentModification = 'error.concurrent.modification';
  static const String errorConcurrentModificationMessage = 'error.concurrent.modification.message';
  static const String errorHeatModified = 'error.heat.modified';
  static const String errorHeatModifiedMessage = 'error.heat.modified.message';
  static const String errorAthleteNotInHeat = 'error.athlete.not.in.heat';
  static const String errorAthleteNotInHeatMessage = 'error.athlete.not.in.heat.message';

  // Resource Gone (HTTP 410) Errors
  static const String errorHeatDeleted = 'error.heat.deleted';
  static const String errorHeatDeletedMessage = 'error.heat.deleted.message';
  static const String errorScoreDeleted = 'error.score.deleted';
  static const String errorScoreDeletedMessage = 'error.score.deleted.message';
  static const String errorResourceGone = 'error.resource.gone';
  static const String errorResourceGoneMessage = 'error.resource.gone.message';

  // Retry Logic
  static const String retryAttempt = 'retry.attempt';
  static const String retryingSubmission = 'retrying.submission';
  static const String retryFailed = 'retry.failed';
  static const String maxRetriesReached = 'max.retries.reached';
  static const String retryInSeconds = 'retry.in.seconds';

  // Score Submission States
  static const String submittingScore = 'submitting.score';
  static const String scoreSubmittedSuccessfully = 'score.submitted.successfully';
  static const String scoreSavedOffline = 'score.saved.offline';
  static const String scoreSyncPending = 'score.sync.pending';

  // CONTINGENCIA 4: Draft Auto-Save
  static const String draftRestored = 'draft.restored';
  static const String draftAutoSaved = 'draft.auto.saved';
  static const String draftCleared = 'draft.cleared';

  // Heat State Updates
  static const String heatClosedBlocking = 'heat.closed.blocking';
  static const String heatClosedRefresh = 'heat.closed.refresh';
  static const String heatStatusChanged = 'heat.status.changed';

  // ==========================================================================
  // 13. OUTBOX PATTERN - CONTINGENCIA 1 (Efecto Estadio)
  // ==========================================================================

  // Outbox Status
  static const String scorePendingSync = 'score.pending.sync';
  static const String scorePendingSyncMessage = 'score.pending.sync.message';
  static const String scoreFailedSync = 'score.failed.sync';
  static const String scoreFailedSyncMessage = 'score.failed.sync.message';
  static const String unsyncedScoresCount = 'unsynced.scores.count';
  static const String syncPendingScores = 'sync.pending.scores';
  static const String retrySync = 'retry.sync';
  static const String retrySyncSingle = 'retry.sync.single';
  static const String retrySyncAll = 'retry.sync.all';

  // Outbox Results
  static const String syncSuccessful = 'sync.successful';
  static const String syncFailed = 'sync.failed';
  static const String syncNoConnection = 'sync.no.connection';
  static const String syncMaxAttemptsReached = 'sync.max.attempts.reached';
  static const String syncBatchComplete = 'sync.batch.complete';
  static const String syncBatchCompleteMessage = 'sync.batch.complete.message';

  // Outbox Warnings
  static const String wifiCollapsed = 'wifi.collapsed';
  static const String wifiCollapsedMessage = 'wifi.collapsed.message';
  static const String scoreWillRetryLater = 'score.will.retry.later';
  static const String tapToRetryManually = 'tap.to.retry.manually';

  // ==========================================================================
  // 14. SCORE VALIDATION - CONTINGENCIA 2 (Dedo Veloz)
  // ==========================================================================

  // Validation Warnings
  static const String scoreValidationWarning = 'score.validation.warning';
  static const String scoreTooHigh = 'score.too.high';
  static const String scoreTooLow = 'score.too.low';
  static const String scoreOutlier = 'score.outlier';
  static const String scoreHistoricalMismatch = 'score.historical.mismatch';
  static const String scoreSuspicious = 'score.suspicious';
  static const String confirmUnusualScore = 'confirm.unusual.score';
  static const String scoreAboveAverage = 'score.above.average';
  static const String scoreBelowAverage = 'score.below.average';
  static const String otherJudgesAverage = 'other.judges.average';
  static const String yourScore = 'your.score';
  static const String difference = 'difference';
  static const String areYouSureThisScore = 'are.you.sure.this.score';

  // Validation Actions
  static const String correctScore = 'correct.score';
  static const String confirmScore = 'confirm.score';
  static const String reviewScore = 'review.score';

  // ==========================================================================
  // 15. HELP GUIDE SYSTEM
  // ==========================================================================

  // General
  static const String helpGuideTitle = 'help.guide.title';
  static const String helpGuideClose = 'help.guide.close';
  static const String helpGuideDontShowAgain = 'help.guide.dont.show.again';
  static const String helpGuideGotIt = 'help.guide.got.it';
  static const String helpGuideNext = 'help.guide.next';
  static const String helpGuidePrevious = 'help.guide.previous';
  static const String helpGuideSkip = 'help.guide.skip';
  static const String helpGuideFinish = 'help.guide.finish';
  static const String helpGuideStepOf = 'help.guide.step.of';

  // Competition Create Guide
  static const String helpGuideCompetitionCreateTitle = 'help.guide.competition.create.title';
  static const String helpGuideCompetitionCreateStep1Title = 'help.guide.competition.create.step1.title';
  static const String helpGuideCompetitionCreateStep1Description = 'help.guide.competition.create.step1.description';
  static const String helpGuideCompetitionCreateStep2Title = 'help.guide.competition.create.step2.title';
  static const String helpGuideCompetitionCreateStep2Description = 'help.guide.competition.create.step2.description';
  static const String helpGuideCompetitionCreateStep3Title = 'help.guide.competition.create.step3.title';
  static const String helpGuideCompetitionCreateStep3Description = 'help.guide.competition.create.step3.description';
  static const String helpGuideCompetitionCreateStep4Title = 'help.guide.competition.create.step4.title';
  static const String helpGuideCompetitionCreateStep4Description = 'help.guide.competition.create.step4.description';
  static const String helpGuideCompetitionCreateStep5Title = 'help.guide.competition.create.step5.title';
  static const String helpGuideCompetitionCreateStep5Description = 'help.guide.competition.create.step5.description';

  // Invite Judges Guide
  static const String helpGuideJudgesInviteTitle = 'help.guide.judges.invite.title';
  static const String helpGuideJudgesInviteStep1Title = 'help.guide.judges.invite.step1.title';
  static const String helpGuideJudgesInviteStep1Description = 'help.guide.judges.invite.step1.description';
  static const String helpGuideJudgesInviteStep2Title = 'help.guide.judges.invite.step2.title';
  static const String helpGuideJudgesInviteStep2Description = 'help.guide.judges.invite.step2.description';
  static const String helpGuideJudgesInviteStep3Title = 'help.guide.judges.invite.step3.title';
  static const String helpGuideJudgesInviteStep3Description = 'help.guide.judges.invite.step3.description';
  static const String helpGuideJudgesInviteStep4Title = 'help.guide.judges.invite.step4.title';
  static const String helpGuideJudgesInviteStep4Description = 'help.guide.judges.invite.step4.description';
  static const String helpGuideJudgesInviteStep5Title = 'help.guide.judges.invite.step5.title';
  static const String helpGuideJudgesInviteStep5Description = 'help.guide.judges.invite.step5.description';

  // Configure Categories Guide
  static const String helpGuideCategoriesConfigTitle = 'help.guide.categories.config.title';
  static const String helpGuideCategoriesConfigStep1Title = 'help.guide.categories.config.step1.title';
  static const String helpGuideCategoriesConfigStep1Description = 'help.guide.categories.config.step1.description';
  static const String helpGuideCategoriesConfigStep2Title = 'help.guide.categories.config.step2.title';
  static const String helpGuideCategoriesConfigStep2Description = 'help.guide.categories.config.step2.description';
  static const String helpGuideCategoriesConfigStep3Title = 'help.guide.categories.config.step3.title';
  static const String helpGuideCategoriesConfigStep3Description = 'help.guide.categories.config.step3.description';
  static const String helpGuideCategoriesConfigStep4Title = 'help.guide.categories.config.step4.title';
  static const String helpGuideCategoriesConfigStep4Description = 'help.guide.categories.config.step4.description';
  static const String helpGuideCategoriesConfigStep5Title = 'help.guide.categories.config.step5.title';
  static const String helpGuideCategoriesConfigStep5Description = 'help.guide.categories.config.step5.description';

  // Manage Participants Guide
  static const String helpGuideParticipantsManageTitle = 'help.guide.participants.manage.title';
  static const String helpGuideParticipantsManageStep1Title = 'help.guide.participants.manage.step1.title';
  static const String helpGuideParticipantsManageStep1Description = 'help.guide.participants.manage.step1.description';
  static const String helpGuideParticipantsManageStep2Title = 'help.guide.participants.manage.step2.title';
  static const String helpGuideParticipantsManageStep2Description = 'help.guide.participants.manage.step2.description';
  static const String helpGuideParticipantsManageStep3Title = 'help.guide.participants.manage.step3.title';
  static const String helpGuideParticipantsManageStep3Description = 'help.guide.participants.manage.step3.description';
  static const String helpGuideParticipantsManageStep4Title = 'help.guide.participants.manage.step4.title';
  static const String helpGuideParticipantsManageStep4Description = 'help.guide.participants.manage.step4.description';
  static const String helpGuideParticipantsManageStep5Title = 'help.guide.participants.manage.step5.title';
  static const String helpGuideParticipantsManageStep5Description = 'help.guide.participants.manage.step5.description';

  // Start Competition Guide
  static const String helpGuideCompetitionStartTitle = 'help.guide.competition.start.title';
  static const String helpGuideCompetitionStartStep1Title = 'help.guide.competition.start.step1.title';
  static const String helpGuideCompetitionStartStep1Description = 'help.guide.competition.start.step1.description';
  static const String helpGuideCompetitionStartStep2Title = 'help.guide.competition.start.step2.title';
  static const String helpGuideCompetitionStartStep2Description = 'help.guide.competition.start.step2.description';
  static const String helpGuideCompetitionStartStep3Title = 'help.guide.competition.start.step3.title';
  static const String helpGuideCompetitionStartStep3Description = 'help.guide.competition.start.step3.description';
  static const String helpGuideCompetitionStartStep4Title = 'help.guide.competition.start.step4.title';
  static const String helpGuideCompetitionStartStep4Description = 'help.guide.competition.start.step4.description';
  static const String helpGuideCompetitionStartStep5Title = 'help.guide.competition.start.step5.title';
  static const String helpGuideCompetitionStartStep5Description = 'help.guide.competition.start.step5.description';

  // Utility
  static const String helpGuideAvailableForRoute = 'help.guide.available.for.route';
  static const String helpGuideNoGuideForRoute = 'help.guide.no.guide.for.route';
}
