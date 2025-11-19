// تست سریع API با fetch
const testAPI = async () => {
  try {
    // 1. لاگین و گرفتن token
    console.log('1️⃣ لاگین...');
    const loginRes = await fetch('http://localhost:3000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'admin', password: 'admin123' })
    });
    
    if (!loginRes.ok) {
      console.error('❌ خطا در لاگین:', loginRes.status);
      return;
    }
    
    const { token } = await loginRes.json();
    console.log('✅ لاگین موفق - Token:', token.substring(0, 20) + '...');
    
    // 2. تست API جستجوی با شماره تلفن
    console.log('\n2️⃣ جستجوی مشتری با شماره 12345678...');
    const searchRes = await fetch('http://localhost:3000/api/customers/by-phone/12345678', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!searchRes.ok) {
      console.error('❌ خطا:', searchRes.status, await searchRes.text());
      return;
    }
    
    const data = await searchRes.json();
    console.log('✅ مشتری پیدا شد:');
    console.log('   نام:', data.customer.name);
    console.log('   شماره‌ها:', data.customer.phoneNumbers);
    
    if (data.lastDocument) {
      console.log('   آخرین سند:', data.lastDocument.documentNumber);
    } else {
      console.log('   آخرین سند: ندارد');
    }
    
    // 3. تست با شماره دیگر
    console.log('\n3️⃣ جستجوی با شماره 09123456789...');
    const searchRes2 = await fetch('http://localhost:3000/api/customers/by-phone/09123456789', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (searchRes2.ok) {
      const data2 = await searchRes2.json();
      console.log('✅ مشتری پیدا شد:', data2.customer.name);
    } else {
      console.log('⚠️  مشتری پیدا نشد');
    }
    
    console.log('\n✅ تست API با موفقیت انجام شد!');
    
  } catch (error) {
    console.error('❌ خطا:', error.message);
  }
};

testAPI();
