# Music Library Feature

## Overview

Your app now has a **persistent music library** that remembers all your music files even after closing the app. You add folders once, and the library maintains permanent links to your files.

## Key Features

### 1. **One-Time Folder Setup**
- Add music folders to your library once
- The app scans the folders and stores track information in a local database
- Files stay linked to their original locations on your hard drive
- No need to rescan every time you open the app

### 2. **Database-Backed Storage**
- Uses SQLite database (`sqflite_common_ffi`) for efficient storage
- Stores track metadata: title, artist, album, file path, size, dates
- Indexed for fast searching across thousands of tracks
- Persistent across app sessions

### 3. **Smart Library Management**

#### Add Folders
```
1. Click "Add Music Folder" button
2. Select folder containing your music
3. App automatically scans for supported audio files
4. Tracks are added to your permanent library
```

#### Manage Folders
- View all added folders in the library
- Remove folders (also removes their tracks)
- Each folder can contain subfolders

#### Supported Audio Formats
- MP3, M4A, AAC
- FLAC, WAV, OGG, OPUS
- WMA (Windows Media Audio)

### 4. **Library Maintenance**

#### Rescan Library
- Updates the library with new files from added folders
- Detects modified files and updates metadata
- Keeps existing tracks that haven't changed

#### Clean Up Missing Files
- Removes tracks whose files no longer exist
- Useful after moving or deleting files outside the app
- Keeps your library in sync with your file system

### 5. **Features**

✅ **Fast Search** - Search by title, artist, or album across entire library
✅ **Track Statistics** - See total track count and folder count
✅ **File Details** - View file path, size, date added
✅ **Play Queue** - Play entire library or search results
✅ **Persistent** - Library survives app restarts
✅ **Efficient** - Database indexes for quick queries

## How It Works

### Database Schema

**library_folders table:**
- Stores paths to folders you've added
- Tracks when each folder was added

**library_tracks table:**
- Stores metadata for each music file
- Links to original file location
- Indexes on title, artist, album for fast search

### File Monitoring

The library:
1. Stores file path and last modified date
2. When rescanning, checks if files have been modified
3. Updates only changed files (efficient rescanning)
4. Original files remain untouched on your drive

### Windows & Linux Support

- **Windows**: Scans local drives (C:, D:, etc.)
- **Linux**: Scans any mounted filesystem
- **Both**: Handles long paths and special characters

## Usage Guide

### Initial Setup
1. Launch the app
2. Go to "Music Library" tab
3. Click "Add Music Folder"
4. Select your main music folder
5. Wait for initial scan to complete
6. Your library is now ready!

### Daily Use
- Search and play music immediately
- No waiting for scans
- Library loads instantly from database

### Maintenance
- **Weekly**: Rescan if you added new files
- **Monthly**: Run "Clean Up Missing Files"
- **As Needed**: Add/remove folders

## Technical Details

### Performance
- **Initial Scan**: Depends on folder size (e.g., 1000 files ~ 30 seconds)
- **App Startup**: Instant (loads from database)
- **Search**: Near-instant (database indexes)
- **Rescan**: Only processes new/modified files

### Storage Location
- Database file: `Documents/music_library.db`
- Typical size: ~1 MB per 10,000 tracks
- Backed up with app data

### Benefits Over Folder Scanning

**Old Approach** (folder scanning):
- Scanned folders every app start
- Slow startup times
- Re-parsed all files repeatedly

**New Approach** (library):
- One-time scan per folder
- Instant startup
- Efficient updates
- Persistent track information

## Troubleshooting

### Tracks Not Appearing
- Check folder path is correct in "Manage Folders"
- Run "Rescan Library"
- Verify files have supported extensions

### Library Size Growing
- Run "Clean Up Missing Files"
- Remove unused folders from library

### Files Moved/Renamed
- Library tracks by file path
- If you move files, remove old folder and add new one
- Or run "Clean Up" then rescan

## Future Enhancements

Possible additions:
- Album artwork extraction
- Metadata editing
- Duplicate detection
- Smart playlists based on metadata
- Play count and statistics
- Library export/import
