class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'farmerRegistration': 'Farmer Registration',
      'enterName': 'Enter your name',
      'enterMobile': 'Enter mobile number',
      'name': 'Name',
      'mobileNumber': 'Mobile Number',
      'state': 'State',
      'district': 'District',
      'block': 'Block',
      'village': 'Village',
      'save': 'Save',
      'selectState': 'Select State',
      'selectDistrict': 'Select District',
      'selectBlock': 'Select Block',
      'selectVillage': 'Select Village',
      'requiredField': 'This field is required',
      'invalidMobile': 'Please enter a valid 10-digit mobile number',
      'savedSuccessfully': 'Farmer information saved successfully',
      'errorSaving': 'Error saving farmer information',
      'profileUpdated': 'Profile updated successfully'
    },
    'ta': {
      'farmerRegistration': 'விவசாயி பதிவு',
      'enterName': 'உங்கள் பெயரை உள்ளிடவும்',
      'enterMobile': 'மொபைல் எண்ணை உள்ளிடவும்',
      'name': 'பெயர்',
      'mobileNumber': 'கைபேசி எண்',
      'state': 'மாநிலம்',
      'district': 'மாவட்டம்',
      'block': 'வட்டாரம்',
      'village': 'கிராமம்',
      'save': 'சேமி',
      'selectState': 'மாநிலத்தைத் தேர்ந்தெடுக்கவும்',
      'selectDistrict': 'மாவட்டத்தைத் தேர்ந்தெடுக்கவும்',
      'selectBlock': 'வட்டாரத்தைத் தேர்ந்தெடுக்கவும்',
      'selectVillage': 'கிராமத்தைத் தேர்ந்தெடுக்கவும்',
      'requiredField': 'இந்த தகவல் தேவை',
      'invalidMobile': 'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்',
      'savedSuccessfully': 'விவசாயி தகவல் வெற்றிகரமாக சேமிக்கப்பட்டது',
      'errorSaving': 'விவசாயி தகவலைச் சேமிப்பதில் பிழை',
      'profileUpdated': 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது'
    }
  };

  static String getText(String key, String languageCode) {
    return translations[languageCode]?[key] ?? translations['en']![key]!;
  }
}