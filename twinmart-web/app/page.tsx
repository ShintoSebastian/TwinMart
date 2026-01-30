import React from 'react';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-[#E2F7F3] to-white p-6">
      
      {/* Brand Logo & Name */}
      <div className="flex items-center gap-3 mb-20">
        <div className="bg-[#1DB98A] p-2.5 rounded-2xl shadow-sm">
          <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <h1 className="text-4xl font-bold tracking-tight text-gray-900">
          Twin<span className="text-[#1DB98A]">Mart</span>
        </h1>
      </div>

      {/* Hero Text */}
      <div className="text-center max-w-sm mb-16">
        <h2 className="text-4xl font-bold text-gray-900 mb-4">
          Welcome to TwinMart
        </h2>
        <p className="text-gray-500 text-lg leading-relaxed">
          Shop smarter, save time, skip the queue — 
          <span className="text-[#1DB98A] font-semibold block">
            works online & offline
          </span>
        </p>
      </div>

      {/* Buttons Container */}
      <div className="w-full max-w-[400px] space-y-5">
        
        {/* Get Started Button (The 3D Green Button) */}
        <button className="
          group relative w-full bg-[#1DB98A] text-white py-5 rounded-full font-bold text-xl
          flex items-center justify-center gap-2 transition-all 
          active:translate-y-1
          shadow-[0_6px_0_#179a73]
          active:shadow-[0_2px_0_#179a73]
          hover:brightness-105
        ">
          Get Started
          <span className="text-2xl">→</span>
        </button>
        
        {/* Login Button (The White/Soft Gray Button) */}
        <button className="
          w-full bg-white text-gray-900 py-5 rounded-full font-bold text-xl
          flex items-center justify-center gap-2 border border-gray-100 
          shadow-lg shadow-gray-100 hover:bg-gray-50 transition-all
        ">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
          </svg>
          Login
        </button>

      </div>
    </main>
  );
}