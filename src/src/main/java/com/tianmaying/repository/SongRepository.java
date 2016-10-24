package com.tianmaying.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tianmaying.model.Song;

public interface SongRepository extends JpaRepository<Song, String> {
    
    List<Song> findByCommentCountGreaterThan(Long commentCount);
    
}
