# 💼 Jobs API - Quick Reference

وثائق سريعة وشاملة لواجهات وظائف التوظيف في Panchit.

---

## 📋 All Endpoints

### Jobs (5 endpoints)
```
✅ GET    /data/jobs                    - Get jobs list (with pagination/filters)
✅ GET    /data/jobs/:id                - Get single job
✅ POST   /data/jobs                    - Create job
✅ PUT    /data/jobs/:id                - Update job
✅ DELETE /data/jobs/:id                - Delete job (POST alias supported)
```

### Categories (1 endpoint)
```
✅ GET    /data/jobs/categories         - Get job categories
```

### Applications & Candidates (2 endpoints)
```
✅ POST   /data/jobs/:id/apply          - Apply to job
✅ GET    /data/jobs/:id/candidates     - List job candidates (owner only)
```

---

## 🎯 Quick Examples

### Get Jobs
```bash
GET /data/jobs
GET /data/jobs?offset=0&limit=20
```

### Get Single Job
```bash
GET /data/jobs/351
```

### Create Job
```bash
POST /data/jobs
{
  "title": "Backend PHP Developer",
  "category": 3,
  "message": "We are hiring a senior PHP developer",
  "location": "Dubai, UAE",
  "salary_minimum": 6000,
  "salary_minimum_currency": "USD",
  "salary_maximum": 9000,
  "salary_maximum_currency": "USD",
  "type": "full_time"
}
```

### Apply to Job
```bash
POST /data/jobs/351/apply
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+123456789",
  "location": "Cairo, Egypt",
  "cv": "uploaded_cv_file_id"
}
```

---

## ✅ Test Status

| Category | Status |
|----------|--------|
| Endpoints | ✅ Working |
| Auth (5 headers) | ✅ Required |
| Error Handling | ✅ Implemented |
| Documentation | ✅ Available |

---

## 📚 Documentation Files

- **JOBS_API.md** - Complete API documentation with Flutter examples
- **test_jobs.sh** - Quick test script using `quick_copy.sh`

---

**API Version:** 1.0  
**Status:** Production Ready ✅  
**Last Updated:** 2025-11-16
