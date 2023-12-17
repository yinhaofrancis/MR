//
//  MRObject.cpp
//  MRender
//
//  Created by wenyang on 2023/12/17.
//

#include "MRObject.hpp"




using namespace MR;

Object::Object():m_ref_count(new int(1)){

}
Object::~Object(){
    release();
}
Object::Object(const Object& m) {
    m_lock.lock();
    m_ref_count = m.m_ref_count;
    (*m_ref_count)++;
    m_lock.unlock();
}

Object::Object(const Object&& m){
    m_lock.lock();
    m_ref_count = m.m_ref_count;
    (*m_ref_count)++;
    m_lock.unlock();
}

Object& Object::operator=(const Object &m){
    m_lock.lock();
    if(m_ref_count != m.m_ref_count){
        (*m_ref_count)--;
        if(*m_ref_count == 0){
            delete m_ref_count;
            m_ref_count = nullptr;
        }
    }
    m_ref_count = m.m_ref_count;
    (*m_ref_count)++;
    m_lock.unlock();
    return *this;
}

Object& Object::operator=(const Object &&m){
    m_lock.lock();
    if(m_ref_count != m.m_ref_count){
        (*m_ref_count)--;
        if(*m_ref_count == 0){
            delete m_ref_count;
            m_ref_count = nullptr;
        }
    }
    m_ref_count = m.m_ref_count;
    (*m_ref_count)++;
    m_lock.unlock();
    return *this;
}

int Object::ref_count(){
    m_lock.lock();
    
    auto count = m_ref_count == nullptr ? 0 : *m_ref_count ;
    m_lock.unlock();
    return count;
}
Object& Object::retain(){
    m_lock.lock();
    (*m_ref_count)++;
    m_lock.unlock();
    return *this;
}
void Object::dealloc(){
    
}
int Object::release(){
    m_lock.lock();
    if(this->m_ref_count == nullptr){
        m_lock.unlock();
        return 0;
    }

    (*m_ref_count)--;
    if(*m_ref_count <= 0){
        delete m_ref_count;
        m_ref_count = nullptr;
        m_lock.unlock();
        dealloc();
        return 0;
    }
    m_lock.unlock();
    return (*m_ref_count);
}
